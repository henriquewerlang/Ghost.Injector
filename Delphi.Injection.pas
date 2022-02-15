unit Delphi.Injection;

interface

uses System.TypInfo, System.Rtti, System.Generics.Collections;

type
  TInjector = class
  private
    FContext: TRttiContext;

    function FindCandidate(const AType: TRttiType; const Params: TArray<TValue>): TRttiMethod;
  public
    constructor Create;

    destructor Destroy; override;

    function Resolve<T>: T; overload;
    function Resolve<T>(const Params: TArray<TValue>): T; overload;
  end;

  TRttiObjectHelper = class helper for TRttiObject
  public
    function GetAttribute<T: TCustomAttribute>: T;
  end;

implementation

uses System.SysUtils;

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

function TInjector.FindCandidate(const AType: TRttiType; const Params: TArray<TValue>): TRttiMethod;
begin
  Result := nil;

  for var AMethod in AType.GetMethods do
    if AMethod.IsConstructor and (Length(AMethod.GetParameters) = Length(Params)) then
      Exit(AMethod);
end;

function TInjector.Resolve<T>(const Params: TArray<TValue>): T;
begin
  var RttiType := FContext.GetType(TypeInfo(T));

  Result := FindCandidate(RttiType, Params).Invoke(RttiType.AsInstance.MetaclassType, Params).AsType<T>;
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

end.

