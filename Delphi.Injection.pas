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

  TFunctionFactory<T> = class(TInterfacedObject, IFactory)
  private
    FFactoryFunction: TFactoryFunction<T>;

    function Construct(const Params: TArray<TValue>): TValue;
  public
    constructor Create(const FactoryFunction: TFactoryFunction<T>);
  end;

  TObjectFactory = class(TInterfacedObject, IFactory)
  private
    FObjectType: TRttiInstanceType;

    function Construct(const Params: TArray<TValue>): TValue;
    function FindConstructorCandidate(const Params: TArray<TValue>): TRttiMethod;
  public
    constructor Create(const RttiType: TRttiInstanceType);
  end;

  TInjector = class
  private
    FContext: TRttiContext;
//    FRegisteredType: TDictionary<TRttiType, TList<IFactory>>;

    function FindConcreteType(const AType: TRttiType): TRttiType;
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
end;

destructor TInjector.Destroy;
begin
  FContext.Free;

  inherited;
end;

function TInjector.FindConcreteType(const AType: TRttiType): TRttiType;
begin
  Result := AType;

  if Result.IsInterface then
    for var RttiType in FContext.GetTypes do
      if RttiType.IsInstance then
        for var InterfaceImplementation in RttiType.AsInstance.GetDeclaredImplementedInterfaces do
          if InterfaceImplementation = AType then
            Exit(RttiType);
end;

procedure TInjector.RegisterFactory<T>(const Factory: T);
begin
//  TObjectFactory.Create(FContext.GetType(T).AsInstance);
end;

procedure TInjector.RegisterFactory<T>(const Factory: TFactoryFunction<T>);
begin

end;

procedure TInjector.RegisterFactory<T>(const Factory: TFunc<T>);
begin

end;

procedure TInjector.RegisterFactory<T>(const Factory: IFactory);
begin

end;

function TInjector.Resolve<T>(const Params: TArray<TValue>): T;
begin
  var RttiType := FindConcreteType(FContext.GetType(TypeInfo(T)));

  Result := TValue.Empty.AsType<T>;
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

{ TFunctionFactory<T> }

function TFunctionFactory<T>.Construct(const Params: TArray<TValue>): TValue;
begin
  Result := TValue.From<T>(FFactoryFunction(Params));
end;

constructor TFunctionFactory<T>.Create(const FactoryFunction: TFactoryFunction<T>);
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

end.

