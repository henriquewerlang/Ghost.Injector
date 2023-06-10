unit Ghost.Injector;

interface

uses System.TypInfo, System.Rtti, System.Generics.Collections, System.SysUtils;

type
  EConstructorParamsMismatch = class(Exception)
  public
    constructor Create(const AType: TRttiType);
  end;

  EFoundMoreThenOneFactory = class(Exception)
  public
    constructor Create(const AType: TRttiType);
  end;

  ETypeFactoryNotRegistered = class(Exception)
  public
    constructor Create(const AType: TRttiType);
  end;

  TInjector = class;

  TFactoryFunction<T> = reference to function(const Params: TArray<TValue>): T;

  IFactory = interface
    function Construct(const Params: TArray<TValue>): TValue;
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

  TInterfaceFactory = class(TFactory, IFactory)
  private
    FFactory: IFactory;
    FInjector: TInjector;
    FInterfaceType: TRttiInterfaceType;

    function Construct(const Params: TArray<TValue>): TValue;
    function FindFactory: IFactory;
    function GetFactory: IFactory;

    property Factory: IFactory read GetFactory;
  public
    constructor Create(const Injector: TInjector; const InterfaceType: TRttiInterfaceType);
  end;

  TObjectFactory = class(TFactory, IFactory)
  private
    FContext: TRttiContext;
    FInjector: TInjector;
    FObjectType: TRttiInstanceType;

    function Construct(const Params: TArray<TValue>): TValue;
    function FindConstructorCandidate(const Params: TArray<TValue>; var ConvertedParams: TArray<TValue>): TRttiMethod;
  public
    constructor Create(const Context: TRttiContext; const Injector: TInjector; const RttiType: TRttiInstanceType);
  end;

  TInjector = class
  private
    FContext: TRttiContext;
    FRegisteredTypes: TDictionary<String, TList<IFactory>>;

    function CreateFactory(const FactoryName: String; const AType: TRttiStructuredType): IFactory;
    function FindFactories(const FactoryName: String; const AType: TRttiStructuredType): TList<IFactory>;
    function GetFactory(const FactoryName: String; const AType: TRttiStructuredType): IFactory;
    function GetRegisterName(const FactoryName: String; const AType: TRttiStructuredType): String;
    function GetStructuredType<T>: TRttiStructuredType; inline;
    function RegisterFactory(const FactoryName: String; const AType: TRttiStructuredType; const Factory: IFactory): TList<IFactory>; overload;
    function Resolve(const FactoryName: String; const &Type: TRttiStructuredType; const Params: TArray<TValue>): TValue; overload;
  public
    constructor Create;

    destructor Destroy; override;

    function Resolve<T>(const FactoryName: String): T; overload;
    function Resolve<T>(const FactoryName: String; const Params: TArray<TValue>): T; overload;
    function Resolve<T>(const Params: TArray<TValue>): T; overload;
    function Resolve<T>: T; overload;
    function ResolveAll<T>(const FactoryName: String): TArray<T>; overload;
    function ResolveAll<T>(const FactoryName: String; const Params: TArray<TValue>): TArray<T>; overload;
    function ResolveAll<T>(const Params: TArray<TValue>): TArray<T>; overload;
    function ResolveAll<T>: TArray<T>; overload;

    procedure RegisterFactory<T>(const Factory: IFactory); overload;
    procedure RegisterFactory<T>(const Factory: T); overload;
    procedure RegisterFactory<T>(const Factory: TFactoryFunction<T>); overload;
    procedure RegisterFactory<T>(const Factory: TFunc<T>); overload;
    procedure RegisterFactory<T>(const FactoryName: String); overload;
    procedure RegisterFactory<T>(const FactoryName: String; const Factory: IFactory); overload;
    procedure RegisterFactory<T>(const FactoryName: String; const Factory: T); overload;
    procedure RegisterFactory<T>(const FactoryName: String; const Factory: TFactoryFunction<T>); overload;
    procedure RegisterFactory<T>(const FactoryName: String; const Factory: TFunc<T>); overload;
    procedure RegisterFactory<T>; overload;
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

constructor ETypeFactoryNotRegistered.Create(const AType: TRttiType);
begin
  inherited CreateFmt('The factory isn''t registered for the type %s!', [AType.QualifiedName]);
end;

{ TInjector }

constructor TInjector.Create;
begin
  inherited;

  FContext := TRttiContext.Create;
  FRegisteredTypes := TObjectDictionary<String, TList<IFactory>>.Create([doOwnsValues]);
end;

function TInjector.CreateFactory(const FactoryName: String; const AType: TRttiStructuredType): IFactory;
begin
  if AType.IsInterface then
    Result := TInterfaceFactory.Create(Self, AType.AsInterface)
  else
    Result := TObjectFactory.Create(FContext, Self, AType.AsInstance);
end;

destructor TInjector.Destroy;
begin
  FContext.Free;

  FRegisteredTypes.Free;

  inherited;
end;

function TInjector.FindFactories(const FactoryName: String; const AType: TRttiStructuredType): TList<IFactory>;
begin
  if not FRegisteredTypes.TryGetValue(GetRegisterName(FactoryName, AType), Result) then
    Result := RegisterFactory(FactoryName, AType, CreateFactory(EmptyStr, AType));
end;

function TInjector.GetFactory(const FactoryName: String; const AType: TRttiStructuredType): IFactory;
begin
  var Factories := FindFactories(FactoryName, AType);

  if Assigned(Factories) then
    if Factories.Count = 1 then
      Result := Factories.First
    else
      raise EFoundMoreThenOneFactory.Create(AType)
  else
    raise ETypeFactoryNotRegistered.Create(AType);
end;

function TInjector.GetRegisterName(const FactoryName: String; const AType: TRttiStructuredType): String;
begin
  Result := Format('%s-%s', [AType.QualifiedName, FactoryName]);
end;

function TInjector.GetStructuredType<T>: TRttiStructuredType;
begin
  Result := FContext.GetType(TypeInfo(T)) as TRttiStructuredType;
end;

procedure TInjector.RegisterFactory<T>(const Factory: T);
begin
  RegisterFactory(EmptyStr, Factory);
end;

procedure TInjector.RegisterFactory<T>(const Factory: TFactoryFunction<T>);
begin
  RegisterFactory<T>(EmptyStr, Factory);
end;

function TInjector.RegisterFactory(const FactoryName: String; const AType: TRttiStructuredType; const Factory: IFactory): TList<IFactory>;
begin
  var RegisterName := GetRegisterName(FactoryName, AType);

  if not FRegisteredTypes.TryGetValue(RegisterName, Result) then
  begin
    Result := TList<IFactory>.Create;

    FRegisteredTypes.Add(RegisterName, Result);
  end;

  Result.Add(Factory);
end;

procedure TInjector.RegisterFactory<T>(const Factory: TFunc<T>);
begin
  RegisterFactory<T>(EmptyStr, Factory);
end;

procedure TInjector.RegisterFactory<T>;
begin
  RegisterFactory<T>(EmptyStr);
end;

function TInjector.Resolve(const FactoryName: String; const &Type: TRttiStructuredType; const Params: TArray<TValue>): TValue;
begin
  Result := GetFactory(FactoryName, &Type).Construct(Params);
end;

function TInjector.Resolve<T>: T;
begin
  Result := Resolve<T>(nil);
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
  Result := Resolve(FactoryName, GetStructuredType<T>, Params).AsType<T>;
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

  for var Factory in FindFactories(FactoryName, GetStructuredType<T>) do
    Result := Result + [Factory.Construct(Params).AsType<T>];
end;

procedure TInjector.RegisterFactory<T>(const FactoryName: String; const Factory: T);
begin
  RegisterFactory<T>(FactoryName, TInstanceFactory.Create(TValue.From(Factory)) as IFactory);
end;

procedure TInjector.RegisterFactory<T>(const FactoryName: String);
begin
  RegisterFactory<T>(FactoryName, CreateFactory(FactoryName, GetStructuredType<T>));
end;

procedure TInjector.RegisterFactory<T>(const FactoryName: String; const Factory: TFactoryFunction<T>);
begin
  RegisterFactory<T>(FactoryName, TFunctionFactory.Create(
    function (const Args: TArray<TValue>): TValue
    begin
      Result := TValue.From(Factory(Args));
    end) as IFactory);
end;

procedure TInjector.RegisterFactory<T>(const Factory: IFactory);
begin
  RegisterFactory<T>(EmptyStr, Factory);
end;

procedure TInjector.RegisterFactory<T>(const FactoryName: String; const Factory: TFunc<T>);
begin
  RegisterFactory<T>(FactoryName,
    function(const Args: TArray<TValue>): T
    begin
      Result := Factory();
    end);
end;

procedure TInjector.RegisterFactory<T>(const FactoryName: String; const Factory: IFactory);
begin
  RegisterFactory(FactoryName, GetStructuredType<T>, Factory);
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

  Result := FindConstructorCandidate(Params, ConvertedParams).Invoke(FObjectType.MetaclassType, ConvertedParams).AsObject;
end;

constructor TObjectFactory.Create(const Context: TRttiContext; const Injector: TInjector; const RttiType: TRttiInstanceType);
begin
  inherited Create;

  FContext := Context;
  FInjector := Injector;
  FObjectType := RttiType;
end;

function TObjectFactory.FindConstructorCandidate(const Params: TArray<TValue>; var ConvertedParams: TArray<TValue>): TRttiMethod;
var
  DefaultConstructor: TRttiMethod;

  function ConvertParams(const AMethod: TRttiMethod): Boolean;
  begin
    var Parameters := AMethod.GetParameters;
    Result := Length(Parameters) = Length(Params);

    if Result then
    begin
      SetLength(ConvertedParams, Length(Parameters));

      for var A := Low(Params) to High(Params) do
        if not Params[A].TryCast(Parameters[A].ParamType.Handle, ConvertedParams[A]) then
          Exit(False);
    end;
  end;

  procedure ResolveAllParams;
  begin
    var Parameters := DefaultConstructor.GetParameters;

    SetLength(ConvertedParams, Length(DefaultConstructor.GetParameters));

    for var A := Low(Parameters) to High(Parameters) do
      ConvertedParams[A] := FInjector.Resolve(EmptyStr, Parameters[A].ParamType as TRttiStructuredType, nil);
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

{ TInterfaceFactory }

function TInterfaceFactory.Construct(const Params: TArray<TValue>): TValue;
begin
  Result := Factory.Construct(Params);
end;

constructor TInterfaceFactory.Create(const Injector: TInjector; const InterfaceType: TRttiInterfaceType);
begin
  inherited Create;

  FInjector := Injector;
  FInterfaceType := InterfaceType;
end;

function TInterfaceFactory.FindFactory: IFactory;
begin
  Result := nil;

  for var AType in FInjector.FContext.GetTypes do
    if AType.IsInstance then
      for var InterfaceType in AType.AsInstance.GetImplementedInterfaces do
        if InterfaceType = FInterfaceType then
          Exit(FInjector.GetFactory(EmptyStr, AType.AsInstance));
end;

function TInterfaceFactory.GetFactory: IFactory;
begin
  if not Assigned(FFactory) then
    FFactory := FindFactory;

  Result := FFactory;
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

{ EFoundMoreThenOneFactory }

constructor EFoundMoreThenOneFactory.Create(const AType: TRttiType);
begin
  inherited CreateFmt('Too many factories for the type "%s"!', [AType.QualifiedClassName]);
end;

{ EConstructorParamsMismatch }

constructor EConstructorParamsMismatch.Create(const AType: TRttiType);
begin
  inherited CreateFmt('The constructor params mismatch for the type %s!', [AType.QualifiedName]);
end;

end.

