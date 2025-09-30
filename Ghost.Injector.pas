unit Ghost.Injector;

interface

uses System.TypInfo, System.Rtti, System.Generics.Collections, System.SysUtils;

type
  EFactoryNotRegistered = class(Exception)
  public
    constructor Create;
  end;

  EFoundMoreThenOneFactory = class(Exception)
  public
    constructor Create;
  end;

  EConstructorParamsMismatch = class(Exception)
  public
    constructor Create(const RttiType: TRttiType);
  end;

  TInjector = class;

  TFactoryFunction<T> = reference to function(const Params: TArray<TValue>): T;

  IFactory = interface
    function Construct(const Params: TArray<TValue>): TValue;
  end;

  TFactoryRegistration = class
  private
    FFactory: IFactory;
  public
    constructor Create(const Factory: IFactory);

    procedure AsSingleton(const OwnsObject: Boolean);

    property Factory: IFactory read FFactory write FFactory;
  end;

  TFunctionFactory = class(TInterfacedObject, IFactory)
  private
    FFactoryFunction: TFactoryFunction<TValue>;

    function Construct(const Params: TArray<TValue>): TValue;
  public
    constructor Create(const FactoryFunction: TFactoryFunction<TValue>);
  end;

  TInstanceFactory = class(TInterfacedObject, IFactory)
  private
    FInstance: TValue;

    function Construct(const Params: TArray<TValue>): TValue;
  public
    constructor Create(const Instance: TValue);
  end;

  TObjectFactory = class(TInterfacedObject, IFactory)
  private
    FInjector: TInjector;
    FObjectType: TRttiInstanceType;

    function Construct(const Params: TArray<TValue>): TValue;
    function FindConstructorCandidate(const Params: TArray<TValue>; var ConvertedParams: TArray<TValue>): TRttiMethod;
  public
    constructor Create(const Injector: TInjector; const RttiType: TRttiInstanceType);
  end;

  TSingletonFactory = class(TInterfacedObject, IFactory)
  private
    FFactory: IFactory;
    FFactoryValue: TValue;
    FOwnsObject: Boolean;

    function Construct(const Params: TArray<TValue>): TValue;
  public
    constructor Create(const Factory: IFactory; const OwnsObject: Boolean);

    destructor Destroy; override;
  end;

  TInjector = class
  private type
    TResolveSituation = (NotFound, Found, MoreThanOneFound);
  private
    FContext: TRttiContext;
    FRegisteredTypes: TDictionary<String, TList<TFactoryRegistration>>;

    function GetFactoryRegister(const FactoryName: String): TList<TFactoryRegistration>;
    function TryResolve(const FactoryName: String; const Params: array of const; var Instance: TValue): TResolveSituation;

    procedure CheckResolveSituation(const Situation: TResolveSituation);
    procedure RegisterTypes(const RttiType: TRttiType);

    property FactoryRegister[const FactoryName: String]: TList<TFactoryRegistration> read GetFactoryRegister;
  public
    constructor Create;

    destructor Destroy; override;

    function RegisterFactory(const FactoryName: String; const Factory: IFactory): TFactoryRegistration; overload;
    function RegisterFactory<T: class>: TFactoryRegistration; overload;
    function RegisterFactory<TI: IInterface; T: class>: TFactoryRegistration; overload;
    function RegisterFactory<TI: IInterface; T: class>(const FactoryName: String): TFactoryRegistration; overload;
    function RegisterFactory<T>(const Instance: T): TFactoryRegistration; overload;
    function RegisterFactory<T>(const FactoryName: String; const Func: TFunc<T>): TFactoryRegistration; overload;
    function RegisterFactory<T>(const Func: TFunc<T>): TFactoryRegistration; overload;
    function Resolve(const FactoryName: String): TValue; overload;
    function Resolve(const FactoryName: String; const Params: array of const): TValue; overload;
    function Resolve(const RttiType: TRttiType; const Params: array of const): TValue; overload;
    function Resolve<T>: T; overload;
    function Resolve<T>(const Params: array of const): T; overload;
    function Resolve<T>(const FactoryName: String): T; overload;
    function Resolve<T>(const FactoryName: String; const Params: array of const): T; overload;

    function ResolveAll<T>(const FactoryName: String): TArray<T>; overload;
    function ResolveAll<T>(const FactoryName: String; const Params: array of const): TArray<T>; overload;
    function ResolveAll<T>(const Params: array of const): TArray<T>; overload;
    function ResolveAll<T>: TArray<T>; overload;
  end;

  TRttiObjectHelper = class helper for TRttiObject
  private
    function GetIsInterface: Boolean; inline;
    function GetAsInterface: TRttiInterfaceType; inline;
  public
    property AsInterface: TRttiInterfaceType read GetAsInterface;
    property IsInterface: Boolean read GetIsInterface;
  end;

implementation

{ EFactoryNotRegistered }

constructor EFactoryNotRegistered.Create;
begin
  inherited Create('The factory isn''t registered!');
end;

{ EFoundMoreThenOneFactory }

constructor EFoundMoreThenOneFactory.Create;
begin
  inherited Create('Too many factories found!');
end;

{ EConstructorParamsMismatch }

constructor EConstructorParamsMismatch.Create(const RttiType: TRttiType);
begin
  inherited CreateFmt('The constructor params mismatch for the type %s!', [RttiType.QualifiedName]);
end;

{ TInjector }

procedure TInjector.CheckResolveSituation(const Situation: TResolveSituation);
begin
  case Situation of
    NotFound: raise EFactoryNotRegistered.Create;
    Found: ;
    MoreThanOneFound: raise EFoundMoreThenOneFactory.Create;
  end;
end;

constructor TInjector.Create;
begin
  inherited;

  FContext := TRttiContext.Create;
  FRegisteredTypes := TObjectDictionary<String, TList<TFactoryRegistration>>.Create([doOwnsValues]);

  RegisterFactory(Self);
end;

destructor TInjector.Destroy;
begin
  FContext.Free;

  FRegisteredTypes.Free;

  inherited;
end;

function TInjector.GetFactoryRegister(const FactoryName: String): TList<TFactoryRegistration>;
begin
  if not FRegisteredTypes.TryGetValue(FactoryName, Result) then
  begin
    Result := TObjectList<TFactoryRegistration>.Create;

    FRegisteredTypes.Add(FactoryName, Result);
  end;
end;

function TInjector.RegisterFactory(const FactoryName: String; const Factory: IFactory): TFactoryRegistration;
begin
  Result := TFactoryRegistration.Create(Factory);

  FactoryRegister[FactoryName].Add(Result);
end;

function TInjector.RegisterFactory<T>(const Instance: T): TFactoryRegistration;
var
  RttiType: TRttiType;
  TheFactory: IFactory;

begin
  RttiType := FContext.GetType(TypeInfo(T));

  case RttiType.TypeKind of
    tkClass,
    tkInterface: TheFactory := TInstanceFactory.Create(TValue.From(Instance));
    else raise Exception.Create('Type not mapped!');
  end;

  Result := RegisterFactory(RttiType.QualifiedName, TheFactory);
end;

function TInjector.RegisterFactory<T>: TFactoryRegistration;
begin
  var RttiType := FContext.GetType(TypeInfo(T));

  Result := RegisterFactory(RttiType.QualifiedName, TObjectFactory.Create(Self, RttiType.AsInstance));
end;

procedure TInjector.RegisterTypes(const RttiType: TRttiType);
begin
  if RttiType.IsInstance then
    RegisterFactory(RttiType.QualifiedName, TObjectFactory.Create(Self, RttiType.AsInstance))
  else if RttiType.IsInterface then
    for var RttiPackage in FContext.GetPackages do
      for var RttiClassType in RttiPackage.GetTypes do
        if RttiClassType.IsInstance then
          for var InterfaceType in RttiClassType.AsInstance.GetImplementedInterfaces do
            if InterfaceType = RttiType.AsInterface then
              RegisterFactory(RttiType.QualifiedName, TObjectFactory.Create(Self, RttiClassType.AsInstance))
end;

function TInjector.Resolve(const FactoryName: String): TValue;
begin
  Result := Resolve(FactoryName, []);
end;

function TInjector.Resolve<T>: T;
begin
  Result := Resolve<T>([]);
end;

function TInjector.TryResolve(const FactoryName: String; const Params: array of const; var Instance: TValue): TResolveSituation;
begin
  var Factories := FactoryRegister[FactoryName];

  case Factories.Count of
    0: Result := NotFound;
    1:
    begin
      Instance := Factories.First.Factory.Construct(ArrayOfConstToTValueArray(Params));
      Result := Found;
    end
    else Result := MoreThanOneFound;
  end;
end;

function TInjector.Resolve<T>(const FactoryName: String): T;
begin
  Result := Resolve<T>(FactoryName, []);
end;

function TInjector.Resolve(const FactoryName: String; const Params: array of const): TValue;
begin
  CheckResolveSituation(TryResolve(FactoryName, Params, Result));
end;

function TInjector.Resolve<T>(const Params: array of const): T;
begin
  Result := Resolve(FContext.GetType(TypeInfo(T)), Params).AsType<T>;
end;

function TInjector.Resolve<T>(const FactoryName: String; const Params: array of const): T;
begin
  Result := Resolve(FactoryName, Params).AsType<T>;
end;

function TInjector.ResolveAll<T>: TArray<T>;
begin
  Result := ResolveAll<T>([]);
end;

function TInjector.ResolveAll<T>(const Params: array of const): TArray<T>;
begin
  var Instance: TValue;
  var RttiType := FContext.GetType(TypeInfo(T));

  var ResolveSituation := TryResolve(RttiType.QualifiedName, Params, Instance);

  if ResolveSituation = Found then
    Result := [Instance.AsType<T>]
  else if ResolveSituation = NotFound then
    RegisterTypes(RttiType);

  Result := ResolveAll<T>(RttiType.QualifiedName, Params);
end;

function TInjector.ResolveAll<T>(const FactoryName: String): TArray<T>;
begin
  Result := ResolveAll<T>(FactoryName, []);
end;

function TInjector.ResolveAll<T>(const FactoryName: String; const Params: array of const): TArray<T>;
begin
  Result := nil;

  for var FactoryRegistration in FactoryRegister[FactoryName] do
    Result := Result + [FactoryRegistration.Factory.Construct(ArrayOfConstToTValueArray(Params)).AsType<T>];
end;

function TInjector.RegisterFactory<T>(const Func: TFunc<T>): TFactoryRegistration;
begin
  Result := RegisterFactory<T>(FContext.GetType(TypeInfo(T)).QualifiedName, Func);
end;

function TInjector.RegisterFactory<T>(const FactoryName: String; const Func: TFunc<T>): TFactoryRegistration;
begin
  Result := RegisterFactory(FactoryName, TFunctionFactory.Create(
    function(const Params: TArray<TValue>): TValue
    begin
      Result := TValue.From(Func());
    end));
end;

function TInjector.RegisterFactory<TI, T>(const FactoryName: String): TFactoryRegistration;
begin
  Result := RegisterFactory(FactoryName, TObjectFactory.Create(Self, FContext.GetType(TypeInfo(T)).AsInstance));
end;

function TInjector.RegisterFactory<TI, T>: TFactoryRegistration;
begin
  Result := RegisterFactory<TI, T>(FContext.GetType(TypeInfo(TI)).QualifiedName);
end;

function TInjector.Resolve(const RttiType: TRttiType; const Params: array of const): TValue;
begin
  var ResolveSituation := TryResolve(RttiType.QualifiedName, Params, Result);

  if ResolveSituation = NotFound then
  begin
    RegisterTypes(RttiType);

    Result := Resolve(RttiType.QualifiedName, Params);
  end
  else
    CheckResolveSituation(ResolveSituation);
end;

{ TRttiObjectHelper }

function TRttiObjectHelper.GetAsInterface: TRttiInterfaceType;
begin
  Result := Self as TRttiInterfaceType;
end;

function TRttiObjectHelper.GetIsInterface: Boolean;
begin
  Result := Self is TRttiInterfaceType;
end;

{ TFunctionFactory }

function TFunctionFactory.Construct(const Params: TArray<TValue>): TValue;
begin
  Result := FFactoryFunction(Params);
end;

constructor TFunctionFactory.Create(const FactoryFunction: TFactoryFunction<TValue>);
begin
  inherited Create;

  FFactoryFunction := FactoryFunction;
end;

{ TObjectFactory }

function TObjectFactory.Construct(const Params: TArray<TValue>): TValue;
begin
  var ConvertedParams: TArray<TValue> := nil;
  var Method := FindConstructorCandidate(Params, ConvertedParams);

  Result := Method.Invoke(FObjectType.MetaclassType, ConvertedParams);
end;

constructor TObjectFactory.Create(const Injector: TInjector; const RttiType: TRttiInstanceType);
begin
  inherited Create;

  FInjector := Injector;
  FObjectType := RttiType;
end;

function TObjectFactory.FindConstructorCandidate(const Params: TArray<TValue>; var ConvertedParams: TArray<TValue>): TRttiMethod;
var
  DefaultConstructor: TRttiMethod;

  Parameters: TArray<TRttiParameter>;

  function TryConvertParamToInterface(const Index: Integer): Boolean;
  var
    Output: IInterface;

  begin
    Result := Supports(Params[Index].AsInterface, Parameters[Index].ParamType.AsInterface.GUID, Output);

    if Result then
      TValue.Make(@Output, Parameters[Index].ParamType.Handle, ConvertedParams[Index]);
  end;

  function TryToConvertParam(const Index: Integer): Boolean;
  begin
    if Parameters[Index].ParamType.IsInterface then
      Result := TryConvertParamToInterface(Index)
    else
      Result := Params[Index].TryCast(Parameters[Index].ParamType.Handle, ConvertedParams[Index]);
  end;

  function ConvertParams(const AMethod: TRttiMethod): Boolean;
  begin
    Parameters := AMethod.GetParameters;
    Result := Length(Parameters) = Length(Params);

    if Result then
    begin
      SetLength(ConvertedParams, Length(Parameters));

      for var A := Low(Params) to High(Params) do
        if not TryToConvertParam(A) then
          Exit(False);
    end;
  end;

  procedure ResolveAllParams;
  begin
    var Parameters := DefaultConstructor.GetParameters;

    SetLength(ConvertedParams, Length(DefaultConstructor.GetParameters));

    for var A := Low(Parameters) to High(Parameters) do
      ConvertedParams[A] := FInjector.Resolve(Parameters[A].ParamType, []);
  end;

begin
  var ConstructorFound := False;
  var CurrentType := FObjectType;
  DefaultConstructor := nil;

  repeat
    for var AMethod in CurrentType.GetDeclaredMethods do
      if AMethod.IsConstructor then
      begin
        ConstructorFound := True;
        DefaultConstructor := AMethod;

        if ConvertParams(AMethod) then
          Exit(AMethod);
      end;

    CurrentType := CurrentType.BaseType;
  until ConstructorFound;

  if Assigned(DefaultConstructor) and (Params = nil) then
  begin
    ResolveAllParams;

    Exit(DefaultConstructor);
  end
  else
    raise EConstructorParamsMismatch.Create(FObjectType);
end;

{ TInstanceFactory }

function TInstanceFactory.Construct(const Params: TArray<TValue>): TValue;
begin
  Result := FInstance;
end;

constructor TInstanceFactory.Create(const Instance: TValue);
begin
  inherited Create;

  FInstance := Instance;
end;

{ TFactoryRegistration }

procedure TFactoryRegistration.AsSingleton(const OwnsObject: Boolean);
begin
  FFactory := TSingletonFactory.Create(FFactory, OwnsObject);
end;

constructor TFactoryRegistration.Create(const Factory: IFactory);
begin
  inherited Create;

  FFactory := Factory;
end;

{ TSingletonFactory }

function TSingletonFactory.Construct(const Params: TArray<TValue>): TValue;
begin
  if FFactoryValue.TypeInfo = nil then
    FFactoryValue := FFactory.Construct(Params);

  Result := FFactoryValue;
end;

constructor TSingletonFactory.Create(const Factory: IFactory; const OwnsObject: Boolean);
begin
  inherited Create;

  FFactory := Factory;
  FOwnsObject := OwnsObject;
end;

destructor TSingletonFactory.Destroy;
begin
  if FOwnsObject and FFactoryValue.IsObjectInstance then
    FFactoryValue.AsObject.Free;

  inherited;
end;

end.

