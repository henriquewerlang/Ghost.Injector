unit Delphi.Injection;

interface

uses System.TypInfo, System.Rtti, System.Generics.Collections;

type
  RegisterType = class(TCustomAttribute)
  private
    FServiceName: String;
  public
    constructor Create; overload;
    constructor Create(const ServiceName: String); overload;

    property ServiceName: String read FServiceName;
  end;

  Implements = class(TCustomAttribute)

  end;

  TDelphiInjectionImplement = class

  end;

  TDelphiInjectionRegistration = class
  private
    FContext: TRttiContext;
    FUnnamedServices: TDictionary<PTypeInfo, TRttiType>;
    FNamedServices: TDictionary<String, TRttiType>;

    function GetCount: Integer;
  public
    constructor Create;

    destructor Destroy; override;

    function Find(Service: PTypeInfo): TRttiType; overload;
    function Find(const ServiceName: String): TRttiType; overload;

    procedure Add(Service: PTypeInfo); overload;
    procedure Add(const ServiceName: String; Service: PTypeInfo); overload;
    procedure RegisterAllTypes;

    property Count: Integer read GetCount;
    property NamedServices: TDictionary<String, TRttiType> read FNamedServices;
    property UnnamedServices: TDictionary<PTypeInfo, TRttiType> read FUnnamedServices;
  end;

  TDelphiInjectionServiceResolver = class

  end;

  TDelphiInjection = class
  private
    FRegistration: TDelphiInjectionRegistration;
    FTypesRegistered: Boolean;

    procedure CheckTypesRegistered;
  public
    constructor Create;

    destructor Destroy; override;

    function RegisterType<T>: TDelphiInjectionRegistration; overload;
    function RegisterType<T>(const ServiceName: String): TDelphiInjectionRegistration; overload;
    function Resolve<T>: T; overload;
    function Resolve<T>(const ServiceName: String): T; overload;

    property Registration: TDelphiInjectionRegistration read FRegistration;
  end;

  TRttiObjectHelper = class helper for TRttiObject
  public
    function GetAttribute<T: TCustomAttribute>: T;
  end;

implementation

uses System.SysUtils;

{ TDelphiInjection }

procedure TDelphiInjection.CheckTypesRegistered;
begin
  if not FTypesRegistered then
    Registration.RegisterAllTypes;

  FTypesRegistered := True;
end;

constructor TDelphiInjection.Create;
begin
  inherited;

  FRegistration := TDelphiInjectionRegistration.Create;
end;

destructor TDelphiInjection.Destroy;
begin
  FRegistration.Free;

  inherited;
end;

function TDelphiInjection.RegisterType<T>: TDelphiInjectionRegistration;
begin
  Registration.Add(TypeInfo(T));
end;

function TDelphiInjection.RegisterType<T>(const ServiceName: String): TDelphiInjectionRegistration;
begin
  Registration.Add(ServiceName, TypeInfo(Integer))
end;

function TDelphiInjection.Resolve<T>: T;
begin
  CheckTypesRegistered;

  Result := Default(T);
end;

function TDelphiInjection.Resolve<T>(const ServiceName: String): T;
begin

end;

{ TDelphiInjectionRegistration }

procedure TDelphiInjectionRegistration.Add(Service: PTypeInfo);
begin
  FUnnamedServices.Add(Service, nil);
end;

procedure TDelphiInjectionRegistration.Add(const ServiceName: String; Service: PTypeInfo);
begin
  NamedServices.Add(ServiceName, nil);
end;

constructor TDelphiInjectionRegistration.Create;
begin
  inherited;

  FContext := TRttiContext.Create;
  FNamedServices := TDictionary<String, TRttiType>.Create;
  FUnnamedServices := TDictionary<PTypeInfo, TRttiType>.Create;
end;

destructor TDelphiInjectionRegistration.Destroy;
begin
  FContext.Free;

  FNamedServices.Free;

  FUnnamedServices.Free;

  inherited;
end;

function TDelphiInjectionRegistration.Find(const ServiceName: String): TRttiType;
begin

end;

function TDelphiInjectionRegistration.Find(Service: PTypeInfo): TRttiType;
begin

end;

function TDelphiInjectionRegistration.GetCount: Integer;
begin
  Result := UnnamedServices.Count + NamedServices.Count;
end;

procedure TDelphiInjectionRegistration.RegisterAllTypes;
begin
  for var RttiType in FContext.GetTypes do
  begin
    var Attribute := RttiType.GetAttribute<RegisterType>;

    if Assigned(Attribute) then
      if Attribute.ServiceName.IsEmpty then
        Add(RttiType.Handle)
      else
        Add(Attribute.ServiceName, RttiType.Handle);
  end;
end;

{ TRttiObjectHelper }

function TRttiObjectHelper.GetAttribute<T>: T;
begin
  Result := nil;

  for var Attribute in GetAttributes do
    if Attribute is T then
      Exit(Attribute as T);
end;

{ RegisterType }

constructor RegisterType.Create(const ServiceName: String);
begin
  Create;

  FServiceName := ServiceName;
end;

constructor RegisterType.Create;
begin
  inherited;
end;

end.

