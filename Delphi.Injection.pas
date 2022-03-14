unit Delphi.Injection;

interface

uses System.TypInfo, System.Rtti, System.Generics.Collections, System.SysUtils;

type
  EConstructorNotFound = class(Exception)
  public
    constructor Create(const AType: TRttiType);
  end;

  TInjector = class
  private
    FContext: TRttiContext;

    function FindConcreteType(const AType: TRttiType): TRttiType;
    function FindConstructorCandidate(const AType: TRttiType; const Params: TArray<TValue>): TRttiMethod;
  public
    constructor Create;

    destructor Destroy; override;

    function Resolve<T>: T; overload;
    function Resolve<T>(const Params: TArray<TValue>): T; overload;
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

function TInjector.FindConstructorCandidate(const AType: TRttiType; const Params: TArray<TValue>): TRttiMethod;

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
  for var AMethod in AType.GetMethods do
    if AMethod.IsConstructor and SameParameters(AMethod) then
      Exit(AMethod);

  raise EConstructorNotFound.Create(AType);
end;

function TInjector.Resolve<T>(const Params: TArray<TValue>): T;
begin
  var RttiType := FindConcreteType(FContext.GetType(TypeInfo(T)));

  Result := FindConstructorCandidate(RttiType, Params).Invoke(RttiType.AsInstance.MetaclassType, Params).AsType<T>;
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

end.

