unit Delphi.Injection;

interface

uses System.TypInfo, System.Rtti, System.Generics.Collections, System.SysUtils;

type
  EConstructorNotFound = class(Exception)
  public
    constructor Create(const AType: TRttiType);
  end;

  TFactoryFunction<T> = reference to function (const Params: TArray<TValue>): T;

  IFactory = interface
    function Construct(const Params: TArray<TValue>): TValue;
  end;

  TFunctionFactory = class(TInterfacedObject, IFactory)
  private
    FFactoryFunction: TFactoryFunction<TValue>;

    function Construct(const Params: TArray<TValue>): TValue;
  public
    constructor Create(const FactoryFunction: TFactoryFunction<TValue>);
  end;

  TObjectFactory = class(TInterfacedObject, IFactory)
  private
    FObjectType: TRttiInstanceType;

    function Construct(const Params: TArray<TValue>): TValue;
    function FindConstructorCandidate(const Params: TArray<TValue>): TRttiMethod;
  public
    constructor Create(const RttiType: TRttiInstanceType);
  end;

  TInterfaceFactory = class(TInterfacedObject, IFactory)
  private
//    FFactory: IFactory;
//
    function Construct(const Params: TArray<TValue>): TValue;
  end;

  TInstanceFactory = class(TInterfacedObject, IFactory)
  private
    FInstance: TObject;

    function Construct(const Params: TArray<TValue>): TValue;
  public
    constructor Create(const Instance: TObject);
  end;

  TInjector = class
  private
    FContext: TRttiContext;
    FRegisteredTypes: TDictionary<TRttiType, TList<IFactory>>;

    procedure RegisterFactory(const AType: TRttiStructuredType; const Factory: IFactory); overload;
  public
    constructor Create;

    destructor Destroy; override;

    function Resolve<T>: T; overload;
    function Resolve<T>(const Params: TArray<TValue>): T; overload;

    procedure RegisterFactory<T: class>(const Factory: T); overload;
    procedure RegisterFactory<T>(const Factory: IFactory); overload;
    procedure RegisterFactory<T>(const Factory: TFactoryFunction<T>); overload;
    procedure RegisterFactory<T>(const Factory: TFunc<T>); overload;
  end;

  TRttiObjectHelper = class helper for TRttiObject
  private
    function GetIsInterface: Boolean;
  public
    function GetAttribute<T: TCustomAttribute>: T;

    property IsInterface: Boolean read GetIsInterface;
  end;

implementation

{ TInjector }

constructor TInjector.Create;
begin
  inherited;

  FContext := TRttiContext.Create;
  FRegisteredTypes := TObjectDictionary<TRttiType, TList<IFactory>>.Create([doOwnsValues]);
end;

destructor TInjector.Destroy;
begin
  FContext.Free;

  FRegisteredTypes.Free;

  inherited;
end;

procedure TInjector.RegisterFactory<T>(const Factory: T);
begin
  RegisterFactory<T>(TInstanceFactory.Create(Factory) as IFactory);
end;

procedure TInjector.RegisterFactory<T>(const Factory: TFactoryFunction<T>);
begin
  RegisterFactory<T>(
    TFunctionFactory.Create(
      function (const Args: TArray<TValue>): TValue
      begin
        Result := TValue.From(Factory(Args));
      end));
end;

procedure TInjector.RegisterFactory(const AType: TRttiStructuredType; const Factory: IFactory);
begin
  var List := TList<IFactory>.Create;

  List.Add(Factory);

  FRegisteredTypes.Add(AType, List);
end;

procedure TInjector.RegisterFactory<T>(const Factory: TFunc<T>);
begin
  RegisterFactory<T>(
    TFunctionFactory.Create(
      function (const Args: TArray<TValue>): TValue
      begin
        Result := TValue.From(Factory());
      end));
end;

procedure TInjector.RegisterFactory<T>(const Factory: IFactory);
begin
  RegisterFactory(FContext.GetType(TypeInfo(T)) as TRttiStructuredType, Factory);
end;

function TInjector.Resolve<T>(const Params: TArray<TValue>): T;
begin
  Result := FRegisteredTypes[FContext.GetType(TypeInfo(T))][0].Construct(Params).AsType<T>;
end;

function TInjector.Resolve<T>: T;
begin
  Result := Resolve<T>(nil);
end;

{ TRttiObjectHelper }

function TRttiObjectHelper.GetAttribute<T>: T;
begin
  Result := nil;

  for var Attribute in GetAttributes do
    if Attribute is T then
      Exit(Attribute as T);
end;

function TRttiObjectHelper.GetIsInterface: Boolean;
begin
  Result := Self is TRttiInterfaceType;
end;

{ EConstructorNotFound }

constructor EConstructorNotFound.Create(const AType: TRttiType);
begin
  inherited CreateFmt('Constructor not found to the type %s!', [AType.QualifiedName]);
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
  var Construcor := FindConstructorCandidate(Params);
  Result := Construcor.Invoke(FObjectType.MetaclassType, Params).AsObject;
end;

constructor TObjectFactory.Create(const RttiType: TRttiInstanceType);
begin
  FObjectType := RttiType;
end;

function TObjectFactory.FindConstructorCandidate(const Params: TArray<TValue>): TRttiMethod;

  function SameParameters(const AMethod: TRttiMethod): Boolean;
  begin
    var Parameters := AMethod.GetParameters;
    Result := Length(Parameters) = Length(Params);

    if Result then
      for var A := 0 to High(Params) do
        if Parameters[A].ParamType.TypeKind <> Params[A].Kind then
          Exit(False);
  end;

begin
  for var AMethod in FObjectType.GetMethods do
    if AMethod.IsConstructor and SameParameters(AMethod) then
      Exit(AMethod);

  raise EConstructorNotFound.Create(FObjectType);
end;

{ TInterfaceFactory }

function TInterfaceFactory.Construct(const Params: TArray<TValue>): TValue;
begin

end;

{ TInstanceFactory }

function TInstanceFactory.Construct(const Params: TArray<TValue>): TValue;
begin
  Result := FInstance;
end;

constructor TInstanceFactory.Create(const Instance: TObject);
begin
  inherited Create;

  FInstance := Instance;
end;

end.

