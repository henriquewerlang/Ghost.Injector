unit Ghost.Injector;

interface

uses System.TypInfo, System.Rtti, System.Generics.Collections, System.SysUtils;

type
  EConstructorParamsMismatch = class(Exception)
  public
    constructor Create(const RttiType: TRttiType);
  end;

  EFoundMoreThenOneFactory = class(Exception)
  public
    constructor Create(const RttiType: TRttiType);
  end;

  ETypeFactoryNotRegistered = class(Exception)
  public
    constructor Create(const RttiType: TRttiType);
  end;

  EInterfaceWithoutGUID = class(Exception)
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

    procedure AsSingleton;

    property Factory: IFactory read FFactory write FFactory;
  end;

  TFactory = class(TInterfacedObject)
  end;

  TFunctionFactory = class(TFactory, IFactory)
  private
    FFactoryFunction: TFactoryFunction<TValue>;

    function Construct(const Params: TArray<TValue>): TValue;
  public
    constructor Create(const FactoryFunction: TFactoryFunction<TValue>);
  end;

  TInstanceFactory = class(TFactory, IFactory)
  private
    FInstance: TValue;

    function Construct(const Params: TArray<TValue>): TValue;
  public
    constructor Create(const Instance: TValue);
  end;

  TObjectFactory = class(TFactory, IFactory)
  private
    FInjector: TInjector;
    FObjectType: TRttiInstanceType;

    function Construct(const Params: TArray<TValue>): TValue;
    function FindConstructorCandidate(const Params: TArray<TValue>; var ConvertedParams: TArray<TValue>): TRttiMethod;
  public
    constructor Create(const Injector: TInjector; const RttiType: TRttiInstanceType);
  end;

  TSingletonFactory = class(TFactory, IFactory)
  private
    FFactory: IFactory;
    FFactoryValue: TValue;

    function Construct(const Params: TArray<TValue>): TValue;
  public
    constructor Create(const Factory: IFactory);

    destructor Destroy; override;
  end;

  TInjector = class
  private
    FContext: TRttiContext;
    FRegisteredTypes: TDictionary<String, TList<TFactoryRegistration>>;

    function FindFactories(const FactoryName: String; const FactoryType: TRttiType): TList<TFactoryRegistration>;
    function GetFactory(const FactoryName: String; const RttiType: TRttiType): IFactory;
    function GetFactoryRegister(const FactoryName: String; const RttiType: TRttiType): TList<TFactoryRegistration>;
    function InternalRegisterFactory(const FactoryName: String; const RttiType: TRttiType; const Factory: IFactory): TList<TFactoryRegistration>;
  public
    constructor Create;

    destructor Destroy; override;

    function Resolve(const FactoryName: String; const &Type: TRttiType; const Params: TArray<TValue>): TValue; overload;
    function Resolve<T>(const FactoryName: String): T; overload;
    function Resolve<T>(const FactoryName: String; const Params: TArray<TValue>): T; overload;
    function Resolve<T>(const Params: TArray<TValue>): T; overload;
    function Resolve<T>(const Params: array of const): T; overload;
    function Resolve<T>: T; overload;
    function ResolveAll<T>(const FactoryName: String): TArray<T>; overload;
    function ResolveAll<T>(const FactoryName: String; const Params: TArray<TValue>): TArray<T>; overload;
    function ResolveAll<T>(const Params: TArray<TValue>): TArray<T>; overload;
    function ResolveAll<T>: TArray<T>; overload;

    function RegisterFactory<T>(const Factory: IFactory): TFactoryRegistration; overload;
    function RegisterFactory<T>(const Factory: T): TFactoryRegistration; overload;
    function RegisterFactory<T>(const Factory: TFactoryFunction<T>): TFactoryRegistration; overload;
    function RegisterFactory<T>(const Factory: TFunc<T>): TFactoryRegistration; overload;
    function RegisterFactory<T: class>(const FactoryName: String): TFactoryRegistration; overload;
    function RegisterFactory<T>(const FactoryName: String; const Factory: IFactory): TFactoryRegistration; overload;
    function RegisterFactory<T>(const FactoryName: String; const Factory: T): TFactoryRegistration; overload;
    function RegisterFactory<T>(const FactoryName: String; const Factory: TFactoryFunction<T>): TFactoryRegistration; overload;
    function RegisterFactory<T>(const FactoryName: String; const Factory: TFunc<T>): TFactoryRegistration; overload;
    function RegisterFactory<T: class>: TFactoryRegistration; overload;
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

{ ETypeFactoryNotRegistered }

constructor ETypeFactoryNotRegistered.Create(const RttiType: TRttiType);
begin
  inherited CreateFmt('The factory isn''t registered for the type %s!', [RttiType.QualifiedName]);
end;

{ EFoundMoreThenOneFactory }

constructor EFoundMoreThenOneFactory.Create(const RttiType: TRttiType);
begin
  inherited CreateFmt('Too many factories for the type "%s"!', [RttiType.QualifiedName]);
end;

{ EConstructorParamsMismatch }

constructor EConstructorParamsMismatch.Create(const RttiType: TRttiType);
begin
  inherited CreateFmt('The constructor params mismatch for the type %s!', [RttiType.QualifiedName]);
end;

{ EInterfaceWithoutGUID }

constructor EInterfaceWithoutGUID.Create(const RttiType: TRttiType);
begin
  inherited CreateFmt('When register an interface, it must have a GUID value, check the interface declaration of the type %s!', [RttiType.QualifiedName]);
end;

{ TInjector }

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

function TInjector.FindFactories(const FactoryName: String; const FactoryType: TRttiType): TList<TFactoryRegistration>;

  procedure RegisterAllObjectsThatImplementsThisInterface;
  begin
    for var RttiType in FContext.GetTypes do
      if RttiType.IsInstance then
        for var InterfaceType in RttiType.AsInstance.GetImplementedInterfaces do
          if InterfaceType = FactoryType.AsInterface then
            InternalRegisterFactory(FactoryName, FactoryType, TObjectFactory.Create(Self, RttiType.AsInstance))
  end;

begin
  Result := GetFactoryRegister(FactoryName, FactoryType);

  if Result.Count = 0 then
    if FactoryType.IsInstance then
      InternalRegisterFactory(FactoryName, FactoryType, TObjectFactory.Create(Self, FactoryType.AsInstance))
    else
      RegisterAllObjectsThatImplementsThisInterface;
end;

function TInjector.GetFactory(const FactoryName: String; const RttiType: TRttiType): IFactory;
begin
  var Factories := FindFactories(FactoryName, RttiType);

  if Factories.Count = 0 then
    raise ETypeFactoryNotRegistered.Create(RttiType)
  else if Factories.Count = 1 then
    Result := Factories.First.Factory
  else
    raise EFoundMoreThenOneFactory.Create(RttiType);
end;

function TInjector.GetFactoryRegister(const FactoryName: String; const RttiType: TRttiType): TList<TFactoryRegistration>;
begin
  var RegisterName := Format('%s-%s', [RttiType.QualifiedName, FactoryName]);

  if not FRegisteredTypes.TryGetValue(RegisterName, Result) then
  begin
    Result := TObjectList<TFactoryRegistration>.Create;

    FRegisteredTypes.Add(RegisterName, Result);
  end;
end;

function TInjector.InternalRegisterFactory(const FactoryName: String; const RttiType: TRttiType; const Factory: IFactory): TList<TFactoryRegistration>;
begin
  if RttiType.IsInterface and RttiType.AsInterface.GUID.IsEmpty then
    raise EInterfaceWithoutGUID.Create(RttiType);

  Result := GetFactoryRegister(FactoryName, RttiType);

  Result.Add(TFactoryRegistration.Create(Factory));
end;

function TInjector.RegisterFactory<T>(const Factory: T): TFactoryRegistration;
begin
  Result := RegisterFactory(EmptyStr, Factory);
end;

function TInjector.RegisterFactory<T>(const Factory: TFactoryFunction<T>): TFactoryRegistration;
begin
  Result := RegisterFactory<T>(EmptyStr, Factory);
end;

function TInjector.RegisterFactory<T>(const Factory: TFunc<T>): TFactoryRegistration;
begin
  Result := RegisterFactory<T>(EmptyStr, Factory);
end;

function TInjector.RegisterFactory<T>: TFactoryRegistration;
begin
  Result := RegisterFactory<T>(EmptyStr);
end;

function TInjector.Resolve(const FactoryName: String; const &Type: TRttiType; const Params: TArray<TValue>): TValue;
begin
  Result := GetFactory(FactoryName, &Type).Construct(Params);
end;

function TInjector.Resolve<T>: T;
begin
  Result := Resolve<T>(nil);
end;

function TInjector.Resolve<T>(const Params: array of const): T;
begin
  Result := Resolve<T>(ArrayOfConstToTValueArray(Params));
end;

function TInjector.Resolve<T>(const Params: TArray<TValue>): T;
begin
  Result := Resolve<T>(EmptyStr, Params);
end;

function TInjector.Resolve<T>(const FactoryName: String): T;
begin
  Result := Resolve<T>(FactoryName, nil);
end;

function TInjector.Resolve<T>(const FactoryName: String; const Params: TArray<TValue>): T;
begin
  Result := Resolve(FactoryName, FContext.GetType(TypeInfo(T)), Params).AsType<T>;
end;

function TInjector.ResolveAll<T>: TArray<T>;
begin
  Result := ResolveAll<T>([]);
end;

function TInjector.ResolveAll<T>(const Params: TArray<TValue>): TArray<T>;
begin
  Result := ResolveAll<T>(EmptyStr, Params);
end;

function TInjector.ResolveAll<T>(const FactoryName: String): TArray<T>;
begin
  Result := ResolveAll<T>(FactoryName, []);
end;

function TInjector.ResolveAll<T>(const FactoryName: String; const Params: TArray<TValue>): TArray<T>;
begin
  Result := nil;

  for var FactoryRegistration in FindFactories(FactoryName, FContext.GetType(TypeInfo(T))) do
    Result := Result + [FactoryRegistration.Factory.Construct(Params).AsType<T>];
end;

function TInjector.RegisterFactory<T>(const FactoryName: String; const Factory: T): TFactoryRegistration;
begin
  Result := RegisterFactory<T>(FactoryName, TInstanceFactory.Create(TValue.From(Factory)) as IFactory);
end;

function TInjector.RegisterFactory<T>(const FactoryName: String): TFactoryRegistration;
begin
  Result := RegisterFactory<T>(FactoryName, TObjectFactory.Create(Self, FContext.GetType(TypeInfo(T)).AsInstance) as IFactory);
end;

function TInjector.RegisterFactory<T>(const FactoryName: String; const Factory: TFactoryFunction<T>): TFactoryRegistration;
begin
  Result := RegisterFactory<T>(FactoryName, TFunctionFactory.Create(
    function (const Args: TArray<TValue>): TValue
    begin
      Result := TValue.From(Factory(Args));
    end) as IFactory);
end;

function TInjector.RegisterFactory<T>(const Factory: IFactory): TFactoryRegistration;
begin
  Result := RegisterFactory<T>(EmptyStr, Factory);
end;

function TInjector.RegisterFactory<T>(const FactoryName: String; const Factory: TFunc<T>): TFactoryRegistration;
begin
  Result := RegisterFactory<T>(FactoryName,
    function(const Args: TArray<TValue>): T
    begin
      Result := Factory();
    end);
end;

function TInjector.RegisterFactory<T>(const FactoryName: String; const Factory: IFactory): TFactoryRegistration;
begin
  Result := InternalRegisterFactory(FactoryName, FContext.GetType(TypeInfo(T)), Factory).Last;
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

  Result := Method.Invoke(FObjectType.MetaclassType, ConvertedParams).AsObject;
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
      ConvertedParams[A] := FInjector.Resolve(EmptyStr, Parameters[A].ParamType, nil);
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

procedure TFactoryRegistration.AsSingleton;
begin
  FFactory := TSingletonFactory.Create(FFactory);
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

constructor TSingletonFactory.Create(const Factory: IFactory);
begin
  inherited Create;

  FFactory := Factory;
end;

destructor TSingletonFactory.Destroy;
begin
  if FFactoryValue.IsObjectInstance then
    FFactoryValue.AsObject.Free;

  inherited;
end;

end.

