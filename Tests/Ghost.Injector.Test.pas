unit Ghost.Injector.Test;

interface

uses DUnitX.TestFramework, System.Rtti, Ghost.Injector, System.Classes;

type
  {TODO -cInjetor: Injetar campos das classes, isso tem que ser via anotação
    * Criar algum tipo de mapeamento, para quando criar a classe já injetar todos os campos requisitados}
  {TODO -cInjetor: Tem um opção de configuração para tentar achar um construtor qualquer, para construir a classe, independente do nível de herança}
  {TODO -cInjetor: Tem que ser possível passar um enumerador para selecionar um serviço a ser criado
    * Ver se é possível usar esse esquema em uma anotação -> utilizando um parâmetro Variant, ele aceita construir a anotação}

  {TODO -cFábrica de objeto: Quando o construtor tiver objetos de parâmetros, tem que verificar se o parâmetro passado é igual ou derivado do parâmetro para aceitar o mesmo}

  [TestFixture]
  TInjectorTest = class
  private
    FContext: TRttiContext;
    FInjector: TInjector;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure WhenRegisterAFactoryMustReturnTheFactoryRegistrationLoaded;
    [Test]
    procedure WhenRegisterAFactoryMustReturnTheFactoryLoaded;
    [Test]
    procedure WhenResolveTheFactoryMustReturnTheInstanceOfTypeRegisteredInTheFactory;
    [Test]
    procedure WhenResolveTheFactoryMustReturnTheInstanceAsExpected;
    [Test]
    procedure WhenTryToResolveAUnregisteredFactoryMystRaiseError;
    [Test]
    procedure WhenTryToResolveAFactoryWithMoreThanOneTypeRegisteredMustRaiseError;
    [Test]
    procedure WhenResolveAFactoryWithParametersMustPassTheValuesToTheFactory;
    [Test]
    procedure WhenResolveWithTheSpecializedFunctionMustReturnTheInstanceAsExpected;
    [Test]
    procedure WhenResolveWithTheSpecializedFunctionUsingParamsMustReturnTheInstanceAsExpected;
    [Test]
    procedure WhenRegisterAFactoryWithTheSpecializedFunctionMustRegisterTheFactoryNameWithTheQualifiedTypeName;
    [Test]
    procedure WhenRegisterAFactoryWithTheSpecializedFunctionUsingAClassInstanceMustRegisterAInstanceFactory;
    [Test]
    procedure WhenResolveATypeFromAFactoryWithTheSpecializedFunctionUsingAClassInstanceMustReturnTheClassInstanceAsExpected;
    [Test]
    procedure WhenRegisterAnInterfaceInstanceMustRegisterAnInstanceFactory;
    [Test]
    procedure WhenResolveATypeFromAFactoryWithTheSpecializedFunctionUsingAInterfaceInstanceMustReturnTheInterfaceInstanceAsExpected;
    [Test]
    procedure WhenRegisterAFunctionInstanceMustRegisterAFunctionFactory;
    [Test]
    procedure WhenResolveATypeFromAFactoryFunctionMustExecuteTheFunctionToResolveTheType;
    [Test]
    procedure WhenRegisterAnClassFactoryMustReturnAnObjectFactory;
    [Test]
    procedure WhenResolveATypeFromAClassFactoryRegisteredMustReturnTheObjectInstanceAsExpected;
    [Test]
    procedure WhenRegisterAnInterfaceWithOneClassMustCreateAnObjectFactory;
    [Test]
    procedure WhenResolveAnInterfaceTypeMustCreateTheObjectAsExpected;
    [Test]
    procedure WhenRegisterAnInterfaceWithOneClassWithNameFactoryMustResolveWithTheFactoryName;
    [Test]
    procedure WhenResolveWithTheSpecializedFunctionMustReturnTheClassInstanceAsExpected;
    [Test]
    procedure WhenResolveWithTheSpecializedWithParamsMustCreateTheClassWithTheParams;
    [Test]
    procedure WhenTryToResolveATypeNotRegisteredMustFindItInTheRttiAndResolveTheType;
    [Test]
    procedure WhenTryToResolveAnInterfaceNotRegisteredMustFindInTheTypeInRttiAndResolveTheType;
    [Test]
    procedure WhenTryToResolveAnTypeNotRegisteredAndCanBeRegisteredMustRaiseError;
    [Test]
    procedure WhenTryToRegisterTheSameFactoryMoreThenOnceCannnotRaiseAnyError;
    [Test]
    procedure WhenResolveAllMustCreateAllTypesRegisteredForFactorySelected;
    [Test]
    procedure WhenTheInterfaceHasNotAnObjectThatImplementTheInterfaceMustRaiseAnError;
    [Test]
    procedure WhenAInterfaceHasMoreTemOneObjectThatImplementsTheInterfaceMustResolveAllObjects;
    [Test]
    procedure WhenTheInjectorIsCreatedItMustRegisterItSelfAsAnInstanceFactory;
    [Test]
    procedure WhenResolveAClassThreeTimesTheClassMustBeConstructedOnlyThreeTimes;
  end;

  [TestFixture]
  TFunctionFactoryTest = class
  public
    [Test]
    procedure WhenUseTheFunctionFactoryMustCallThePassedFunctionToFactory;
    [Test]
    procedure WhenCallTheFactoryConstructorMustPassTheParamsToTheFunction;
    [Test]
    procedure TheConstructorFunctionMustReturnTheInstanceOfTheObjectCreated;
    [Test]
    procedure TheInstanceCreatedMustBeTheTypeExpected;
  end;

  [TestFixture]
  TObjectFactoryTest = class
  private
    FContext: TRttiContext;
    FInjector: TInjector;

    function CreateObjectFactory(const AClass: TClass): IFactory;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure WhenCallTheConstructMustCreateTheClassInsideTheFactory;
    [Test]
    procedure WhenTheClassHasAConstrutorMustCallThisConstructorOnTheFactory;
    [Test]
    procedure WhenTheClassConstructorHasParamsThisParamsMustBePassedInTheInvokerOfTheConstuctor;
    [TestCase('No param', '123,abc')]
    [TestCase('One param', '456,abc,456')]
    [TestCase('Two params', '789,def,789,def')]
    procedure WhenTheClassHasMoreThenOneContructorMustSelectTheConstructorByTheCountOfTheParams(ExpectParam1: Integer; ExpectParam2: String; ParamValue1: Integer; ParamValue2: String);
    [Test]
    procedure WhenCantFindAConstructorMustRaiseAnError;
    [TestCase('String param', '0,abc')]
    [TestCase('Integer param', '123,')]
    procedure WhenTheClassHasMoreThenOneContructorWithSameQuantityOfParamsMustSelectTheConstructorByTheParamType(const IntegerParam: Integer; const StringParam: String);
    [Test]
    procedure ThisFactoryCanOnlyUsePublicConstructors;
    [Test]
    procedure WhenTheClassDontHaveAnyPublicConstructorsMustRaiseError;
    [Test]
    procedure WhenTheConstructorParamsIsntTheSameMustRaiseExceptionOfMismatchParams;
    [Test]
    procedure TheFactoryCanOnlyUseTheConstructorFromTheCurrentDerivation;
    [Test]
    procedure WhenAClassHasNoConstructorMustSearchInTheBaseClassTheConstructor;
    [Test]
    procedure WhenTheParamCanBeConvertedInAnotherTypeToCreateCantRaiseAnyError;
    [Test]
    procedure TheValuePassedInTheParamsMustBeConvertedAndPassedToTheObjectContructor;
    [Test]
    procedure WhenResolveAnObjectWithoutParamsMustCreateTheObjectWithLastConstructorInTheClass;
    [Test]
    procedure WhenResolveAnObjectWithoutParamsMustResolveTheParamsAutomaticAndReturnTheObject;
  end;

  [TestFixture]
  TInstanceFactoryTest = class
  public
    [Test]
    procedure WhenCallTheFactoryConstructorMustReturnTheInstanceOfTheClass;
  end;

  [TestFixture]
  TRttiObjectHelperTest = class
  private
    FContext: TRttiContext;
  public
    [Setup]
    procedure Setup;
    [Teardown]
    procedure Teardown;
    [Test]
    procedure TheFunctionIsInterfaceMustReturnTrueIfTheTypeIsAnInterface;
    [Test]
    procedure ThePropertyAsInterfaceMustConvertTheCurrentObjectInAnInterfaceRttiType;
  end;

  [TestFixture]
  TSingletonFactoryTest = class
  public
    [Test]
    procedure WhenConstructTheFactoryMustPassTheParamsToTheInternalFactory;
    [Test]
    procedure TheConstructorOfTheFactoryMustBeCalledOnlyOnce;
    [Test]
    procedure TheConstructorMustReturnTheFactoryValue;
    [Test]
    procedure WhenTheFactoryOwnsTheObjectMustDestroyWhenTheFactoryIsDestroyed;
    [Test]
    procedure WhenTheFactoryDontOwnsTheObjectCantDestroyTheObjectAfterTheFactoryIsDestroyed;
    [Test]
    procedure IfTheOwnedObjectIsntAnObjectCantDestroyTheObjectWhenTheFactoryIsDestroyed;
  end;

  TSimpleClass = class
  end;

  TClassWithConstructor = class
  private
    FTheConstructorCalled: Boolean;
  public
    constructor Create;

    property TheConstructorCalled: Boolean read FTheConstructorCalled write FTheConstructorCalled;
  end;

  TClassWithParamsInConstructor = class
  private
    FParam1: TObject;
    FParam2: Integer;
  public
    constructor Create(Param1: TObject; Param2: Integer);

    property Param1: TObject read FParam1 write FParam1;
    property Param2: Integer read FParam2 write FParam2;
  end;

  TClassWithThreeContructors = class
  private
    FParam1: Integer;
    FParam2: String;
  public
    constructor Create; overload;
    constructor Create(Param: Integer); overload;
    constructor Create(Param1: Integer; Param2: String); overload;

    property Param1: Integer read FParam1 write FParam1;
    property Param2: String read FParam2 write FParam2;
  end;

  TClassWithConstructorWithTheSameParameterCount = class
  private
    FIntegerProperty: Integer;
    FStringProperty: String;
  public
    constructor Create(Param: Integer); overload;
    constructor Create(Param: String); overload;

    property IntegerProperty: Integer read FIntegerProperty write FIntegerProperty;
    property StringProperty: String read FStringProperty write FStringProperty;
  end;

  TClassWithPrivateAndProtectedConstructors = class
  private
    constructor Create(const Value: String); overload;
  protected
    constructor Create(const Value: Integer); overload;
  end;

  TClassWithPublicAndPublishedConstructors = class
  private
    FDoubleValue: Double;
    FObjectValue: TObject;
  public
    constructor Create(const Value: Double); overload;
  published
    constructor Create(const Value: TObject); overload;
  end;

  TClassBase = class
  public
    constructor Create(const Value: String);
  end;

  TClassDerived = class(TClassBase)
  public
    constructor Create(const Value: Integer);
  end;

  TClassDerivedMoreOne = class(TClassDerived)
  end;

  TClassWithMoreConstructors = class
  private
    FObject: TObject;
    FConstructorCalled: String;
  public
    constructor Create(const Value: TClassDerivedMoreOne); overload;
    constructor Create(const Value: TClassDerived); overload;
    constructor Create(const Value: TObject); overload;

    destructor Destroy; override;

    property ConstructorCalled: String read FConstructorCalled;
    property &Object: TObject read FObject;
  end;

  TClassWithObjectConstructor = class
  private
    FValue: TClassWithConstructor;
  public
    constructor Create(const Value: TClassWithConstructor);

    destructor Destroy; override;

    property Value: TClassWithConstructor read FValue;
  end;

  TClassWithConstructorCounter = class
  private
    class var FCounter: Integer;
  public
    constructor Create;

    class property Counter: Integer read FCounter write FCounter;
  end;

  IMyInterface = interface
    ['{904F4775-6482-447C-8FDA-849036C92077}']
  end;

  IAnotherInterface = interface
    ['{0175C2F6-765D-43B3-B409-04B449B2DAEE}']
  end;

  IMyInterfaceWithMoreTheOneObject = interface
    ['{F0D4CC42-A631-4D02-BFFD-A972B4BCDA88}']
  end;

  IInterfaceWithoutGUID = interface

  end;

  TMyObjectInterface = class(TInterfacedObject, IMyInterface, IMyInterfaceWithMoreTheOneObject)
  end;

  TMyInterfaceWithMoreTheOneObject = class(TInterfacedObject, IMyInterfaceWithMoreTheOneObject)
  end;

  {$M-}
  TClassNotRegistered = class
  end;
  {$M+}

  TMyClassWithInterfaceInConstructor = class
  public
    constructor Create(const Param: IMyInterface);
  end;

  TMyClassWithDestructor = class(TInterfacedObject, IMyInterfaceWithMoreTheOneObject)
  public
    class var DestroyCalled: Boolean;

    constructor Create;

    destructor Destroy; override;
  end;

implementation

uses System.TypInfo, System.SysUtils, Translucent;

{ TInjectorTest }

procedure TInjectorTest.Setup;
begin
  FContext := TRttiContext.Create;
  FInjector := TInjector.Create;

  TMock.CreateInterface<IFactory>;
end;

procedure TInjectorTest.TearDown;
begin
  FContext.Free;

  FInjector.Free;
end;

procedure TInjectorTest.WhenAInterfaceHasMoreTemOneObjectThatImplementsTheInterfaceMustResolveAllObjects;
begin
  var Objects := FInjector.ResolveAll<IMyInterfaceWithMoreTheOneObject>;

  Assert.AreEqual(3, Length(Objects));
end;

procedure TInjectorTest.WhenRegisterAFactoryMustReturnTheFactoryLoaded;
begin
  var FactoryRegister := FInjector.RegisterFactory('MyFactory', TInstanceFactory.Create(Self));

  Assert.IsNotNull(FactoryRegister.Factory);
end;

procedure TInjectorTest.WhenRegisterAFactoryMustReturnTheFactoryRegistrationLoaded;
begin
  var FactoryRegister := FInjector.RegisterFactory('MyFactory', TInstanceFactory.Create(Self));

  Assert.IsNotNull(FactoryRegister);
end;

procedure TInjectorTest.WhenRegisterAFactoryWithTheSpecializedFunctionMustRegisterTheFactoryNameWithTheQualifiedTypeName;
begin
  FInjector.RegisterFactory(Self);

  Assert.WillNotRaise(
    procedure
    begin
      FInjector.Resolve(TInjectorTest.QualifiedClassName);
    end);
end;

procedure TInjectorTest.WhenRegisterAFactoryWithTheSpecializedFunctionUsingAClassInstanceMustRegisterAInstanceFactory;
begin
  var FactoryRegistration := FInjector.RegisterFactory(Self);

  Assert.AreEqual(TInstanceFactory, TObject(FactoryRegistration.Factory).ClassType);
end;

procedure TInjectorTest.WhenRegisterAFunctionInstanceMustRegisterAFunctionFactory;
begin
  var FactoryRegistration := FInjector.RegisterFactory<TObject>(
    function: TObject
    begin
      raise Exception.Create('Can''t execute!');
    end);

  Assert.AreEqual(TFunctionFactory, TObject(FactoryRegistration.Factory).ClassType);
end;

procedure TInjectorTest.WhenRegisterAnClassFactoryMustReturnAnObjectFactory;
begin
  var FactoryRegistration := FInjector.RegisterFactory<TMyObjectInterface>;

  Assert.IsNotNull(FactoryRegistration);

  Assert.AreEqual(TObjectFactory, TObject(FactoryRegistration.Factory).ClassType);
end;

procedure TInjectorTest.WhenRegisterAnInterfaceInstanceMustRegisterAnInstanceFactory;
begin
  var FactoryRegistration := FInjector.RegisterFactory(TMyObjectInterface.Create as IMyInterface);

  Assert.AreEqual(TInstanceFactory, TObject(FactoryRegistration.Factory).ClassType);
end;

procedure TInjectorTest.WhenRegisterAnInterfaceWithOneClassMustCreateAnObjectFactory;
begin
  var FactoryRegistration := FInjector.RegisterFactory<IMyInterfaceWithMoreTheOneObject, TMyInterfaceWithMoreTheOneObject>;

  Assert.IsNotNull(FactoryRegistration);

  Assert.AreEqual(TObjectFactory, TObject(FactoryRegistration.Factory).ClassType);
end;

procedure TInjectorTest.WhenRegisterAnInterfaceWithOneClassWithNameFactoryMustResolveWithTheFactoryName;
begin
  FInjector.RegisterFactory<IMyInterfaceWithMoreTheOneObject, TMyInterfaceWithMoreTheOneObject>('My Factory');

  var MyInterface := FInjector.Resolve('My Factory').AsType<IMyInterfaceWithMoreTheOneObject>;

  Assert.IsNotNull(MyInterface);
end;

procedure TInjectorTest.WhenResolveAClassThreeTimesTheClassMustBeConstructedOnlyThreeTimes;
begin
  TClassWithConstructorCounter.Counter := 0;

  FInjector.Resolve<TClassWithConstructorCounter>.Free;

  FInjector.Resolve<TClassWithConstructorCounter>.Free;

  FInjector.Resolve<TClassWithConstructorCounter>.Free;

  Assert.AreEqual(3, TClassWithConstructorCounter.Counter);
end;

procedure TInjectorTest.WhenResolveAFactoryWithParametersMustPassTheValuesToTheFactory;
begin
  FInjector.RegisterFactory('MyFactory', TObjectFactory.Create(FInjector, FContext.GetType(TClassWithConstructorWithTheSameParameterCount).AsInstance));

  var MyClass := FInjector.Resolve('MyFactory', [123]).AsType<TClassWithConstructorWithTheSameParameterCount>;

  Assert.AreEqual(123, MyClass.IntegerProperty);

  MyClass.Free;
end;

procedure TInjectorTest.WhenResolveAllMustCreateAllTypesRegisteredForFactorySelected;
begin
  var CalledFunction1 := False;
  var CalledFunction2 := False;
  var CalledFunction3 := False;

  FInjector.RegisterFactory<IMyInterface>(
    function: IMyInterface
    begin
      CalledFunction1 := True;
      Result := nil;
    end);

  FInjector.RegisterFactory<IMyInterface>(
    function: IMyInterface
    begin
      CalledFunction2 := True;
      Result := nil;
    end);

  FInjector.RegisterFactory<IMyInterface>(
    function: IMyInterface
    begin
      CalledFunction3 := True;
      Result := nil;
    end);

  var ResolvedValues := FInjector.ResolveAll<IMyInterface>;

  Assert.AreEqual<NativeInt>(3, Length(ResolvedValues));

  Assert.IsTrue(CalledFunction1 and CalledFunction2 and CalledFunction3);
end;

procedure TInjectorTest.WhenResolveAnInterfaceTypeMustCreateTheObjectAsExpected;
begin
  FInjector.RegisterFactory<IMyInterfaceWithMoreTheOneObject, TMyInterfaceWithMoreTheOneObject>;

  var MyInterface := FInjector.Resolve('Ghost.Injector.Test.IMyInterfaceWithMoreTheOneObject').AsType<IMyInterfaceWithMoreTheOneObject>;

  Assert.IsNotNull(MyInterface);
end;

procedure TInjectorTest.WhenResolveATypeFromAClassFactoryRegisteredMustReturnTheObjectInstanceAsExpected;
begin
  FInjector.RegisterFactory<TMyObjectInterface>;

  var MyObject := FInjector.Resolve(TMyObjectInterface.QualifiedClassName).AsType<TMyObjectInterface>;

  Assert.IsNotNull(MyObject);

  MyObject.Free;
end;

procedure TInjectorTest.WhenResolveATypeFromAFactoryFunctionMustExecuteTheFunctionToResolveTheType;
begin
  FInjector.RegisterFactory<TObject>(
    function: TObject
    begin
      Result := Self;
    end);

  Assert.AreEqual<TObject>(Self, FInjector.Resolve(TObject.QualifiedClassName).AsObject);
end;

procedure TInjectorTest.WhenResolveATypeFromAFactoryWithTheSpecializedFunctionUsingAClassInstanceMustReturnTheClassInstanceAsExpected;
begin
  FInjector.RegisterFactory(Self);

  Assert.AreEqual<TObject>(Self, FInjector.Resolve(QualifiedClassName).AsObject);
end;

procedure TInjectorTest.WhenResolveATypeFromAFactoryWithTheSpecializedFunctionUsingAInterfaceInstanceMustReturnTheInterfaceInstanceAsExpected;
begin
  var MyInterface := TMyObjectInterface.Create as IMyInterface;

  FInjector.RegisterFactory(MyInterface);

  Assert.AreEqual(MyInterface, FInjector.Resolve('Ghost.Injector.Test.IMyInterface').AsType<IMyInterface>);
end;

procedure TInjectorTest.WhenResolveTheFactoryMustReturnTheInstanceAsExpected;
begin
  FInjector.RegisterFactory('MyFactory', TInstanceFactory.Create(Self));

  Assert.AreEqual<TObject>(Self, FInjector.Resolve('MyFactory').AsObject);
end;

procedure TInjectorTest.WhenResolveTheFactoryMustReturnTheInstanceOfTypeRegisteredInTheFactory;
begin
  FInjector.RegisterFactory('MyFactory', TInstanceFactory.Create(Self));

  Assert.IsNotNull(FInjector.Resolve('MyFactory').AsObject);
end;

procedure TInjectorTest.WhenResolveWithTheSpecializedFunctionMustReturnTheClassInstanceAsExpected;
begin
  FInjector.RegisterFactory<TMyObjectInterface>;

  var MyClass := FInjector.Resolve<TMyObjectInterface>;

  Assert.IsNotNull(MyClass);

  MyClass.Free;
end;

procedure TInjectorTest.WhenResolveWithTheSpecializedFunctionMustReturnTheInstanceAsExpected;
begin
  FInjector.RegisterFactory('MyFactory', TInstanceFactory.Create(Self));

  var MyClass := FInjector.Resolve<TInjectorTest>('MyFactory');

  Assert.IsNotNull(MyClass);
end;

procedure TInjectorTest.WhenResolveWithTheSpecializedFunctionUsingParamsMustReturnTheInstanceAsExpected;
begin
  FInjector.RegisterFactory('MyFactory', TObjectFactory.Create(FInjector, FContext.GetType(TClassWithConstructorWithTheSameParameterCount).AsInstance));

  var MyClass := FInjector.Resolve<TClassWithConstructorWithTheSameParameterCount>('MyFactory', [123]);

  Assert.AreEqual(123, MyClass.IntegerProperty);

  MyClass.Free;
end;

procedure TInjectorTest.WhenResolveWithTheSpecializedWithParamsMustCreateTheClassWithTheParams;
begin
  FInjector.RegisterFactory<TClassWithConstructorWithTheSameParameterCount>;

  var MyClass := FInjector.Resolve<TClassWithConstructorWithTheSameParameterCount>([1234]);

  Assert.IsNotNull(MyClass);

  Assert.AreEqual(1234, MyClass.IntegerProperty);

  MyClass.Free;
end;

procedure TInjectorTest.WhenTheInjectorIsCreatedItMustRegisterItSelfAsAnInstanceFactory;
begin
  Assert.AreEqual(FInjector, FInjector.Resolve<TInjector>);
end;

procedure TInjectorTest.WhenTheInterfaceHasNotAnObjectThatImplementTheInterfaceMustRaiseAnError;
begin
  Assert.WillRaise(
    procedure
    begin
      FInjector.Resolve<IAnotherInterface>;
    end, EFactoryNotRegistered);
end;

procedure TInjectorTest.WhenTryToRegisterTheSameFactoryMoreThenOnceCannnotRaiseAnyError;
begin
  Assert.WillNotRaise(
    procedure
    begin
      FInjector.RegisterFactory<TSimpleClass>;

      FInjector.RegisterFactory<TSimpleClass>;

      FInjector.RegisterFactory<TSimpleClass>;
    end);
end;

procedure TInjectorTest.WhenTryToResolveAFactoryWithMoreThanOneTypeRegisteredMustRaiseError;
begin
  FInjector.RegisterFactory('MyFactory', TInstanceFactory.Create(Self));

  FInjector.RegisterFactory('MyFactory', TInstanceFactory.Create(Self));

  FInjector.RegisterFactory('MyFactory', TInstanceFactory.Create(Self));

  Assert.WillRaise(
    procedure
    begin
      FInjector.Resolve('MyFactory');
    end, EFoundMoreThenOneFactory);
end;

procedure TInjectorTest.WhenTryToResolveAnInterfaceNotRegisteredMustFindInTheTypeInRttiAndResolveTheType;
begin
  var MyInterface: IMyInterface := nil;

  Assert.WillNotRaise(
    procedure
    begin
      MyInterface := FInjector.Resolve<IMyInterface>;
    end);

  Assert.IsNotNull(MyInterface);

  MyInterface := nil;
end;

procedure TInjectorTest.WhenTryToResolveAnTypeNotRegisteredAndCanBeRegisteredMustRaiseError;
begin
  Assert.WillRaise(
    procedure
    begin
      FInjector.Resolve<Integer>;
    end);
end;

procedure TInjectorTest.WhenTryToResolveATypeNotRegisteredMustFindItInTheRttiAndResolveTheType;
begin
  var MyClass: TSimpleClass := nil;

  Assert.WillNotRaise(
    procedure
    begin
      MyClass := FInjector.Resolve<TSimpleClass>;
    end);

  Assert.IsNotNull(MyClass);

  MyClass.Free;
end;

procedure TInjectorTest.WhenTryToResolveAUnregisteredFactoryMystRaiseError;
begin
  Assert.WillRaise(
    procedure
    begin
      FInjector.Resolve('MyFactory');
    end, EFactoryNotRegistered);
end;

{ TClassWithConstructor }

constructor TClassWithConstructor.Create;
begin
  inherited;

  FTheConstructorCalled := True;
end;

{ TClassWithParamsInConstructor }

constructor TClassWithParamsInConstructor.Create(Param1: TObject; Param2: Integer);
begin
  inherited Create;

  FParam1 := Param1;
  FParam2 := Param2;
end;

{ TClassWithThreeContructors }

constructor TClassWithThreeContructors.Create;
begin
  Create(123);
end;

constructor TClassWithThreeContructors.Create(Param: Integer);
begin
  Create(Param, 'abc');
end;

constructor TClassWithThreeContructors.Create(Param1: Integer; Param2: String);
begin
  inherited Create;

  FParam1 := Param1;
  FParam2 := Param2;
end;

{ TClassWithConstructorWithTheSameParameterCount }

constructor TClassWithConstructorWithTheSameParameterCount.Create(Param: String);
begin
  inherited Create;

  FStringProperty := Param;
end;

constructor TClassWithConstructorWithTheSameParameterCount.Create(Param: Integer);
begin
  inherited Create;

  FIntegerProperty := Param;
end;

{ TFunctionFactoryTest }

procedure TFunctionFactoryTest.TheConstructorFunctionMustReturnTheInstanceOfTheObjectCreated;
begin
  var Factory := TFunctionFactory.Create(
    function (const Params: TArray<TValue>): TValue
    begin
      Result := TSimpleClass.Create;
    end) as IFactory;

  var Instance := Factory.Construct(nil);

  Assert.IsNotNull(Instance.AsObject);

  Instance.AsObject.Free;
end;

procedure TFunctionFactoryTest.TheInstanceCreatedMustBeTheTypeExpected;
begin
  var Factory := TFunctionFactory.Create(
    function (const Params: TArray<TValue>): TValue
    begin
      Result := TSimpleClass.Create;
    end) as IFactory;

  var Instance := Factory.Construct(nil);

  Assert.AreEqual<TClass>(TSimpleClass, Instance.AsObject.ClassType);

  Instance.AsObject.Free;
end;

procedure TFunctionFactoryTest.WhenCallTheFactoryConstructorMustPassTheParamsToTheFunction;
begin
  var Factory := TFunctionFactory.Create(
    function (const Params: TArray<TValue>): TValue
    begin
      Assert.AreEqual<NativeInt>(1, Length(Params));

      Assert.AreEqual(25, Params[0].AsInteger);

      Result := TSimpleClass.Create;
    end) as IFactory;

  var Instance := Factory.Construct([25]);

  Instance.AsObject.Free;
end;

procedure TFunctionFactoryTest.WhenUseTheFunctionFactoryMustCallThePassedFunctionToFactory;
begin
  var CalledFunction := False;
  var Factory := TFunctionFactory.Create(
    function (const Params: TArray<TValue>): TValue
    begin
      CalledFunction := True;
      Result := TSimpleClass.Create;
    end) as IFactory;

  var Instance := Factory.Construct(nil);

  Instance.AsObject.Free;

  Assert.IsTrue(CalledFunction);
end;

{ TObjectFactoryTest }

function TObjectFactoryTest.CreateObjectFactory(const AClass: TClass): IFactory;
begin
  Result := TObjectFactory.Create(FInjector, FContext.GetType(AClass).AsInstance) as IFactory;
end;

procedure TObjectFactoryTest.Setup;
begin
  FContext := TRttiContext.Create;
  FInjector := TInjector.Create;
end;

procedure TObjectFactoryTest.TearDown;
begin
  FContext.Free;

  FInjector.Free;
end;

procedure TObjectFactoryTest.TheFactoryCanOnlyUseTheConstructorFromTheCurrentDerivation;
begin
  var Factory := CreateObjectFactory(TClassDerived);

  Assert.WillRaise(
    procedure
    begin
      Factory.Construct(['abc']).AsType<TClassDerived>;
    end, EConstructorParamsMismatch);

  Factory := nil;
end;

procedure TObjectFactoryTest.TheValuePassedInTheParamsMustBeConvertedAndPassedToTheObjectContructor;
begin
  var Factory := CreateObjectFactory(TClassWithPublicAndPublishedConstructors);
  var TheObject := Factory.Construct([1234]).AsType<TClassWithPublicAndPublishedConstructors>;

  Assert.AreEqual<Double>(1234, TheObject.FDoubleValue);

  TheObject.Free;
end;

procedure TObjectFactoryTest.ThisFactoryCanOnlyUsePublicConstructors;
begin
  var Factory := CreateObjectFactory(TClassWithPublicAndPublishedConstructors);

  Assert.WillNotRaise(
    procedure
    begin
      Factory.Construct([123.456]).AsType<TClassWithPublicAndPublishedConstructors>.Free;
    end);

  Assert.WillNotRaise(
    procedure
    begin
      Factory.Construct([Self]).AsType<TClassWithPublicAndPublishedConstructors>.Free;
    end);

  Factory := nil;
end;

procedure TObjectFactoryTest.WhenAClassHasNoConstructorMustSearchInTheBaseClassTheConstructor;
begin
  var Factory := CreateObjectFactory(TClassDerivedMoreOne);
  var TheObject := Factory.Construct([1234]).AsObject;

  Assert.IsNotNull(TheObject);

  TheObject.Free;
end;

procedure TObjectFactoryTest.WhenCallTheConstructMustCreateTheClassInsideTheFactory;
begin
  var Factory := CreateObjectFactory(TSimpleClass);
  var TheObject := Factory.Construct(nil).AsObject;

  Assert.IsNotNull(TheObject);

  TheObject.Free;
end;

procedure TObjectFactoryTest.WhenCantFindAConstructorMustRaiseAnError;
begin
  var Factory := CreateObjectFactory(TSimpleClass);

  Assert.WillRaise(
    procedure
    begin
      Factory.Construct([123]).AsObject.Free;
    end);
end;

procedure TObjectFactoryTest.WhenResolveAnObjectWithoutParamsMustCreateTheObjectWithLastConstructorInTheClass;
begin
  var Factory := CreateObjectFactory(TClassWithMoreConstructors);
  var TheObject := Factory.Construct(nil).AsType<TClassWithMoreConstructors>;

  Assert.AreEqual(TObject.ClassName, TheObject.ConstructorCalled);

  TheObject.Free;
end;

procedure TObjectFactoryTest.WhenResolveAnObjectWithoutParamsMustResolveTheParamsAutomaticAndReturnTheObject;
begin
  var Factory := CreateObjectFactory(TClassWithObjectConstructor);
  var TheObject := Factory.Construct(nil).AsType<TClassWithObjectConstructor>;

  Assert.IsNotNull(TheObject.Value);

  TheObject.Free;
end;

procedure TObjectFactoryTest.WhenTheClassConstructorHasParamsThisParamsMustBePassedInTheInvokerOfTheConstuctor;
begin
  var AnObject := TObject.Create;
  var Factory := CreateObjectFactory(TClassWithParamsInConstructor);
  var TheObject := Factory.Construct([AnObject, 1234]).AsType<TClassWithParamsInConstructor>;

  Assert.IsNotNull(TheObject);

  Assert.AreEqual(AnObject, TheObject.Param1);

  Assert.AreEqual(1234, TheObject.Param2);

  AnObject.Free;

  TheObject.Free;
end;

procedure TObjectFactoryTest.WhenTheClassDontHaveAnyPublicConstructorsMustRaiseError;
begin
  var Factory := CreateObjectFactory(TClassWithPrivateAndProtectedConstructors);

  Assert.WillRaise(
    procedure
    begin
      Factory.Construct(['abc']).AsType<TClassWithPrivateAndProtectedConstructors>;
    end);

  Assert.WillRaise(
    procedure
    begin
      Factory.Construct([123]).AsType<TClassWithPrivateAndProtectedConstructors>;
    end);

  Factory := nil;
end;

procedure TObjectFactoryTest.WhenTheClassHasAConstrutorMustCallThisConstructorOnTheFactory;
begin
  var Factory := CreateObjectFactory(TClassWithConstructor);
  var TheObject := Factory.Construct(nil).AsType<TClassWithConstructor>;

  Assert.IsTrue(TheObject.TheConstructorCalled);

  TheObject.Free;
end;

procedure TObjectFactoryTest.WhenTheClassHasMoreThenOneContructorMustSelectTheConstructorByTheCountOfTheParams(ExpectParam1: Integer; ExpectParam2: String; ParamValue1: Integer; ParamValue2: String);
begin
  var Factory := CreateObjectFactory(TClassWithThreeContructors);
  var Params: TArray<TValue> := nil;

  if ParamValue1 > 0 then
  begin
    SetLength(Params, 1);
    Params[0] := ParamValue1;
  end;

  if not ParamValue2.IsEmpty then
  begin
    SetLength(Params, 2);
    Params[1] := ParamValue2;
  end;

  var AClass := Factory.Construct(Params).AsType<TClassWithThreeContructors>;

  Assert.IsNotNull(AClass);

  Assert.AreEqual(ExpectParam1, AClass.Param1);

  Assert.AreEqual(ExpectParam2, AClass.Param2);

  AClass.Free;
end;

procedure TObjectFactoryTest.WhenTheClassHasMoreThenOneContructorWithSameQuantityOfParamsMustSelectTheConstructorByTheParamType(const IntegerParam: Integer; const StringParam: String);
begin
  var Factory := CreateObjectFactory(TClassWithConstructorWithTheSameParameterCount);
  var Param: TValue;

  if IntegerParam > 0 then
    Param := IntegerParam
  else
    Param := StringParam;

  var AClass := Factory.Construct([Param]).AsType<TClassWithConstructorWithTheSameParameterCount>;

  Assert.IsNotNull(AClass);

  Assert.AreEqual(IntegerParam, AClass.IntegerProperty);

  Assert.AreEqual(StringParam, AClass.StringProperty);

  AClass.Free;
end;

procedure TObjectFactoryTest.WhenTheConstructorParamsIsntTheSameMustRaiseExceptionOfMismatchParams;
begin
  var Factory := CreateObjectFactory(TClassWithPublicAndPublishedConstructors);

  Assert.WillRaise(
    procedure
    begin
      Factory.Construct(['123']).AsType<TClassWithPublicAndPublishedConstructors>;
    end, EConstructorParamsMismatch);

  Factory := nil;
end;

procedure TObjectFactoryTest.WhenTheParamCanBeConvertedInAnotherTypeToCreateCantRaiseAnyError;
begin
  var Factory := CreateObjectFactory(TClassWithPublicAndPublishedConstructors);
  var TheObject: TObject := nil;

  Assert.WillNotRaise(
    procedure
    begin
      TheObject := Factory.Construct([1234]).AsObject;
    end);

  TheObject.Free;
end;

{ TInstanceFactoryTest }

procedure TInstanceFactoryTest.WhenCallTheFactoryConstructorMustReturnTheInstanceOfTheClass;
begin
  var AClass := TSimpleClass.Create;
  var AFactory := TInstanceFactory.Create(AClass) as IFactory;
  var TheObject := AFactory.Construct(nil).AsType<TSimpleClass>;

  Assert.AreEqual(AClass, TheObject);

  AClass.Free;
end;

{ TRttiObjectHelperTest }

procedure TRttiObjectHelperTest.Setup;
begin
  FContext := TRttiContext.Create;
end;

procedure TRttiObjectHelperTest.Teardown;
begin
  FContext.Free;
end;

procedure TRttiObjectHelperTest.TheFunctionIsInterfaceMustReturnTrueIfTheTypeIsAnInterface;
begin
  var AType := FContext.GetType(TypeInfo(IMyInterface));

  Assert.IsTrue(AType.IsInterface);
end;

procedure TRttiObjectHelperTest.ThePropertyAsInterfaceMustConvertTheCurrentObjectInAnInterfaceRttiType;
begin
  var AType := FContext.GetType(TypeInfo(IMyInterface)).AsInterface;

  Assert.IsNotNull(AType);

  Assert.AreEqual(TRttiInterfaceType, AType.ClassType);
end;

{ TClassWithPrivateAndProtectedConstructor }

constructor TClassWithPrivateAndProtectedConstructors.Create(const Value: String);
begin

end;

constructor TClassWithPrivateAndProtectedConstructors.Create(const Value: Integer);
begin
  Create(Value.ToString);
end;

{ TClassWithPublicAndPublishedConstructors }

constructor TClassWithPublicAndPublishedConstructors.Create(const Value: TObject);
begin
  FObjectValue := Value;
end;

constructor TClassWithPublicAndPublishedConstructors.Create(const Value: Double);
begin
  FDoubleValue := Value;
end;

{ TClassBase }

constructor TClassBase.Create(const Value: String);
begin

end;

{ TClassDerived }

constructor TClassDerived.Create(const Value: Integer);
begin

end;

{ TClassWithObjectConstructor }

constructor TClassWithObjectConstructor.Create(const Value: TClassWithConstructor);
begin
  FValue := Value;
end;

destructor TClassWithObjectConstructor.Destroy;
begin
  FValue.Free;

  inherited;
end;

{ TClassWithMoreConstructors }

constructor TClassWithMoreConstructors.Create(const Value: TClassDerivedMoreOne);
begin
  FConstructorCalled := 'TClassDerivedMoreOne';
  FObject := Value;
end;

constructor TClassWithMoreConstructors.Create(const Value: TClassDerived);
begin
  FConstructorCalled := 'TClassDerived';
  FObject := Value;
end;

constructor TClassWithMoreConstructors.Create(const Value: TObject);
begin
  FConstructorCalled := 'TObject';
  FObject := Value;
end;

destructor TClassWithMoreConstructors.Destroy;
begin
  FObject.Free;

  inherited;
end;

{ TMyClassWithInterfaceInConstructor }

constructor TMyClassWithInterfaceInConstructor.Create(const Param: IMyInterface);
begin

end;

{ TSingletonFactoryTest }

procedure TSingletonFactoryTest.IfTheOwnedObjectIsntAnObjectCantDestroyTheObjectWhenTheFactoryIsDestroyed;
begin
  var MyClass := TMyClassWithDestructor.Create;

  var SingletonFactory := TSingletonFactory.Create(TInstanceFactory.Create(TValue.From(MyClass as IMyInterfaceWithMoreTheOneObject)), True) as IFactory;

  SingletonFactory.Construct(nil);

  SingletonFactory := nil;

  Assert.IsFalse(MyClass.DestroyCalled);
end;

procedure TSingletonFactoryTest.TheConstructorMustReturnTheFactoryValue;
begin
  var Factory := TFunctionFactory.Create(
    function (const Params: TArray<TValue>): TValue
    begin
      Result := 10;
    end);
  var SingletonFactory := TSingletonFactory.Create(Factory, False) as IFactory;

  var Value := SingletonFactory.Construct(nil);

  Assert.AreEqual(10, Value.AsInteger);
end;

procedure TSingletonFactoryTest.TheConstructorOfTheFactoryMustBeCalledOnlyOnce;
begin
  var PassCount := 0;

  var Factory := TFunctionFactory.Create(
    function (const Params: TArray<TValue>): TValue
    begin
      Result := 0;

      Inc(PassCount);
    end);
  var SingletonFactory := TSingletonFactory.Create(Factory, False) as IFactory;

  SingletonFactory.Construct(nil);

  SingletonFactory.Construct(nil);

  SingletonFactory.Construct(nil);

  Assert.AreEqual(1, PassCount);
end;

procedure TSingletonFactoryTest.WhenConstructTheFactoryMustPassTheParamsToTheInternalFactory;
begin
  var ParamCount := 0;

  var Factory := TFunctionFactory.Create(
    function (const Params: TArray<TValue>): TValue
    begin
      ParamCount := Length(Params);
      Result := 0;
    end);
  var SingletonFactory := TSingletonFactory.Create(Factory, False) as IFactory;

  SingletonFactory.Construct([1, 2]);

  Assert.AreEqual(2, ParamCount);
end;

procedure TSingletonFactoryTest.WhenTheFactoryDontOwnsTheObjectCantDestroyTheObjectAfterTheFactoryIsDestroyed;
begin
  var MyClass := TMyClassWithDestructor.Create;

  var SingletonFactory := TSingletonFactory.Create(TInstanceFactory.Create(MyClass), False) as IFactory;

  SingletonFactory.Construct(nil);

  SingletonFactory := nil;

  Assert.IsFalse(MyClass.DestroyCalled);

  MyClass.Free;
end;

procedure TSingletonFactoryTest.WhenTheFactoryOwnsTheObjectMustDestroyWhenTheFactoryIsDestroyed;
begin
  var MyClass := TMyClassWithDestructor.Create;

  var SingletonFactory := TSingletonFactory.Create(TInstanceFactory.Create(MyClass), True) as IFactory;

  SingletonFactory.Construct(nil);

  SingletonFactory := nil;

  Assert.IsTrue(MyClass.DestroyCalled);
end;

{ TMyClassWithDestructor }

constructor TMyClassWithDestructor.Create;
begin
  DestroyCalled := False;
end;

destructor TMyClassWithDestructor.Destroy;
begin
  DestroyCalled := True;

  inherited;
end;

{ TClassWithConstructorCounter }

constructor TClassWithConstructorCounter.Create;
begin
  inherited;

  Inc(FCounter);
end;

end.

