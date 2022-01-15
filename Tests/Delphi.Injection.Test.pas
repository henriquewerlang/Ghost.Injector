unit Delphi.Injection.Test;

interface

uses DUnitX.TestFramework, System.Rtti, Delphi.Injection;

type
{
  Função para localizar um serviço registrado
  Quando criar o serviço, tem que encontrar o construtor correto, ou dar um erro
  Registrar serviço pelo nome, vai atributo
}
  [TestFixture]
  TDelphiInjectionRegistrationTest = class
  public
    [SetupFixture]
    procedure SetupFixture;
    [Test]
    procedure WhenAddAServiceByTypeMustBeAddedToTheUnnamedList;
    [Test]
    procedure WhenAddAServiceByTypeInfoMustResolveTheRttiTypeAndAddToUnnamedList;
    [Test]
    procedure TheServiceRegisteredByRttiTypeMustBeInTheDictionary;
    [Test]
    procedure TheServiceRegisteredByTypeInfoMustBeInTheDictionary;
    [Test]
    procedure WhenAddANamedServiceMustAddToTheNamedServiceList;
    [Test]
    procedure TheAddedNamedServiceByRttiTypeMustBeInTheNamedListDictionary;
    [Test]
    procedure WhenAddANamedServiceByTypeInfoMustAddToTheNamedServiceList;
    [Test]
    procedure TheAddedNamedServiceByTypeInfoMustBeInTheNamedListDictionary;
    [Test]
    procedure WhenCallRegisterAllServicesMustRegisterAllServicesWithTheRegisterTypeAttribute;
    [Test]
    procedure WhenTheRegisterTypeAttributeHasAServiceNameTheTypeMustBeRegisteredInNamedServiceList;
    [Test]
    procedure TheServiceRegisteredCountMustBeTheCountOfAllServicesRegistered;
  end;

  [TestFixture]
  TDelphiInjectionTest = class
  public
    [SetupFixture]
    procedure SetupFixture;
    [Test]
    procedure WhenTryToResolveATypeMustRegisterAllTypesAutomatically;
    [Test]
    procedure WhenTryToResolveATypeMustRegisterAllTypesAutomaticallyJustOnce;
    [Test]
    procedure WhenCallTheRegisterMustAddTheServiceToTheRegistrationList;
    [Test]
    procedure TheRegisteredTypeMustBeInTheRegistrationListAsExpected;
    [Test]
    procedure WhenRegisterAServiceByNameMustBeAddedToTheRegistrationList;
    [Test]
    procedure TheNameRegisteredMustBeTheSamePassedInTheRegisterTypeFunction;
    [Test]
    procedure WhenTryToResolveARegisteredTypeMustReturnTheInstanceOfThisServiceCreated;
  end;

  [TestFixture]
  TDelphiInjectionServiceResolverTest = class
  public
  end;

  [TestFixture]
  TRttiObjectHelperTest = class
  public
    [Test]
    procedure WhenCallGetAttributeMustReturnTheAttributePassedInParams;
    [Test]
    procedure TheAttributeMustBeTheSameTypeInCallingParam;
  end;

  [Implements]
  [RegisterType]
  TMyService = class
  end;

  [RegisterType]
  TMyAnotherService = class
  end;

  [RegisterType('NamedService')]
  TMyNamedService = class
  end;

implementation

uses System.TypInfo;

{ TDelphiInjectionTest }

procedure TDelphiInjectionTest.SetupFixture;
begin
  var Context := TRttiContext.Create;

  for var RttiType in Context.GetTypes do
    RttiType.GetAttributes;

  Context.Free;
end;

procedure TDelphiInjectionTest.TheNameRegisteredMustBeTheSamePassedInTheRegisterTypeFunction;
begin
  var Injector := TDelphiInjection.Create;

  Injector.RegisterType<TMyService>('MyService');

  Assert.AreEqual('MyService', Injector.Registration.NamedServices.Keys.ToArray[0]);

  Injector.Free;
end;

procedure TDelphiInjectionTest.TheRegisteredTypeMustBeInTheRegistrationListAsExpected;
begin
  var Injector := TDelphiInjection.Create;

  Injector.RegisterType<TMyService>;

  Assert.AreEqual<PTypeInfo>(TypeInfo(TMyService), Injector.Registration.UnnamedServices.Keys.ToArray[0]);

  Injector.Free;
end;

procedure TDelphiInjectionTest.WhenCallTheRegisterMustAddTheServiceToTheRegistrationList;
begin
  var Injector := TDelphiInjection.Create;

  Injector.RegisterType<TMyService>;

  Assert.AreEqual(1, Injector.Registration.Count);

  Injector.Free;
end;

procedure TDelphiInjectionTest.WhenRegisterAServiceByNameMustBeAddedToTheRegistrationList;
begin
  var Injector := TDelphiInjection.Create;

  Injector.RegisterType<TMyService>('MyService');

  Assert.AreEqual(1, Injector.Registration.Count);

  Injector.Free;
end;

procedure TDelphiInjectionTest.WhenTryToResolveARegisteredTypeMustReturnTheInstanceOfThisServiceCreated;
begin
  var Injector := TDelphiInjection.Create;
  var MyService := Injector.Resolve<TMyService>;

  Assert.IsNotNull(MyService);

  Injector.Free;
end;

procedure TDelphiInjectionTest.WhenTryToResolveATypeMustRegisterAllTypesAutomatically;
begin
  var Injector := TDelphiInjection.Create;

  Injector.Resolve<TMyService>;

  Assert.AreEqual(3, Injector.Registration.Count);

  Injector.Free;
end;

procedure TDelphiInjectionTest.WhenTryToResolveATypeMustRegisterAllTypesAutomaticallyJustOnce;
begin
  var Injector := TDelphiInjection.Create;

  Injector.Resolve<TMyService>;

  Injector.Resolve<TMyService>;

  Injector.Resolve<TMyService>;

  Assert.AreEqual(3, Injector.Registration.Count);

  Injector.Free;
end;

{ TDelphiInjectionRegistrationTest }

procedure TDelphiInjectionRegistrationTest.SetupFixture;
begin
  var Context := TRttiContext.Create;

  for var RttiType in Context.GetTypes do
    RttiType.GetAttributes;

  Context.Free;
end;

procedure TDelphiInjectionRegistrationTest.TheAddedNamedServiceByRttiTypeMustBeInTheNamedListDictionary;
begin
  var Registration := TDelphiInjectionRegistration.Create;

  Registration.Add('MyService', TypeInfo(TMyService));

  Assert.AreEqual('MyService', Registration.NamedServices.Keys.ToArray[0]);

  Registration.Free;
end;

procedure TDelphiInjectionRegistrationTest.TheAddedNamedServiceByTypeInfoMustBeInTheNamedListDictionary;
begin
  var Registration := TDelphiInjectionRegistration.Create;

  Registration.Add('MyService', TypeInfo(TMyService));

  Assert.AreEqual('MyService', Registration.NamedServices.Keys.ToArray[0]);

  Registration.Free;
end;

procedure TDelphiInjectionRegistrationTest.TheServiceRegisteredByRttiTypeMustBeInTheDictionary;
begin
  var Registration := TDelphiInjectionRegistration.Create;

  Registration.Add(TypeInfo(TMyService));

  Assert.AreEqual<PTypeInfo>(TypeInfo(TMyService), Registration.UnnamedServices.Keys.ToArray[0]);

  Registration.Free;
end;

procedure TDelphiInjectionRegistrationTest.TheServiceRegisteredByTypeInfoMustBeInTheDictionary;
begin
  var Registration := TDelphiInjectionRegistration.Create;

  Registration.Add(TypeInfo(TMyService));

  Assert.AreEqual<PTypeInfo>(TypeInfo(TMyService), Registration.UnnamedServices.Keys.ToArray[0]);

  Registration.Free;
end;

procedure TDelphiInjectionRegistrationTest.TheServiceRegisteredCountMustBeTheCountOfAllServicesRegistered;
begin
  var Registration := TDelphiInjectionRegistration.Create;

  Registration.Add(TypeInfo(TMyService));
  Registration.Add('MyService', TypeInfo(TMyService));

  Assert.AreEqual(2, Registration.Count);

  Registration.Free;
end;

procedure TDelphiInjectionRegistrationTest.WhenAddANamedServiceByTypeInfoMustAddToTheNamedServiceList;
begin
  var Registration := TDelphiInjectionRegistration.Create;

  Registration.Add('MyService', TypeInfo(TMyService));

  Assert.AreEqual(1, Registration.NamedServices.Count);

  Registration.Free;
end;

procedure TDelphiInjectionRegistrationTest.WhenAddANamedServiceMustAddToTheNamedServiceList;
begin
  var Registration := TDelphiInjectionRegistration.Create;

  Registration.Add('MyService', TypeInfo(TMyService));

  Assert.AreEqual(1, Registration.NamedServices.Count);

  Registration.Free;
end;

procedure TDelphiInjectionRegistrationTest.WhenAddAServiceByTypeInfoMustResolveTheRttiTypeAndAddToUnnamedList;
begin
  var Registration := TDelphiInjectionRegistration.Create;

  Registration.Add(TypeInfo(TMyService));

  Assert.AreEqual(1, Registration.UnnamedServices.Count);

  Registration.Free;
end;

procedure TDelphiInjectionRegistrationTest.WhenAddAServiceByTypeMustBeAddedToTheUnnamedList;
begin
  var Registration := TDelphiInjectionRegistration.Create;

  Registration.Add(TypeInfo(TMyService));

  Assert.AreEqual(1, Registration.UnnamedServices.Count);

  Registration.Free;
end;

procedure TDelphiInjectionRegistrationTest.WhenCallRegisterAllServicesMustRegisterAllServicesWithTheRegisterTypeAttribute;
begin
  var Registration := TDelphiInjectionRegistration.Create;

  Registration.RegisterAllTypes;

  Assert.AreEqual(2, Registration.UnnamedServices.Count);

  Registration.Free;
end;

procedure TDelphiInjectionRegistrationTest.WhenTheRegisterTypeAttributeHasAServiceNameTheTypeMustBeRegisteredInNamedServiceList;
begin
  var Registration := TDelphiInjectionRegistration.Create;

  Registration.RegisterAllTypes;

  Assert.AreEqual(1, Registration.NamedServices.Count);

  Registration.Free;
end;

{ TRttiObjectHelperTest }

procedure TRttiObjectHelperTest.TheAttributeMustBeTheSameTypeInCallingParam;
begin
  var Context := TRttiContext.Create;
  var RttiType := Context.GetType(TMyService);

  var Attribute := RttiType.GetAttribute<RegisterType>;

  Assert.AreEqual(RegisterType, Attribute.ClassType);

  Context.Free;
end;

procedure TRttiObjectHelperTest.WhenCallGetAttributeMustReturnTheAttributePassedInParams;
begin
  var Context := TRttiContext.Create;
  var RttiType := Context.GetType(TMyService);

  var Attribute := RttiType.GetAttribute<RegisterType>;

  Assert.IsNotNull(Attribute);

  Context.Free;
end;

end.
