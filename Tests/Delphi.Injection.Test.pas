unit Delphi.Injection.Test;

interface

uses DUnitX.TestFramework, System.Rtti, Delphi.Injection, System.Classes;

type
{
  Injetor
  - Injetar campos das classes, isso tem que ser via anotação
  - Tem um opção de configuração para tentar achar um construtor qualquer, para construir a classe, independente do nível de herança
  - Criar um esquema de construção atrasado, como um LazyFactory
    * Como foi feito no ORM para valores, mas nesse caso é para construir o objeto concreto

  Fábrica de interface
  - Tem que localizar os tipos concretos, o qual implementam essa classe e registrar para construir a mesma com essa classe
  - Localizar uma classe que implementa ela
    * Tem que verificar se as classes encontradas tem alguma anotação de nome de serviço. Se tiver, verificar se o parâmetro e nome de serviço fecha. Se encontrar mais de uma
      fechando os critérios, por nome de serviço ou padrão, tem que dar erro
  - Por uma anotação de qual classe deve ser criada
    * Teria que ser o nome, senão teria problema de referência circular

  Fábrica de objeto
  - Quando o construtor tiver objetos de parâmetros, tem que verificar se o parâmetro passado é igual ou derivado do parâmetro para aceitar o mesmo
  - Se no nível atual não tiver um construtor tem que ir para a base da classe, e assim por diante até encontrar o construtor do TObject
    * Tem que verificar se a classe sendo contruída tem construtor, se tiver e não conseguir construir tem que dar erro
    * Isso tem que ocorrer em todos os níveis, salvo, não encontrar contrutor em nível nenhum
  - Lançar um erro quando não encontrar todos os parâmetros do construtor da classe
  - Quando resolver uma classe, tem que encontrar todos os tipos esperados no contrutor da classe
  - Como definir qual objeto derivado utilizar no construtor?
    * Provavelmente terei que utilizar anotações por não saber qual escolher
      ** Péssima ideia, é mais provavel mandar resolver o tipo que precisa, e passar para o resolvedor
    * Mesmo assim pode existir mais de uma opção, mas resolver o problema do parâmetro se uma classe base
  - Tem localizar os contrutores da própria classe
  - Senão encontrar contrutores na própria classe, tem que ir descendo os níveis, no primeiro que encontrar, tem que utilizar algum contrutor desse nível
    * Se os parâmetros não forem iguais, tem que dar erro
    * Se a classe tem derivações, e em algum nível de derivação exitir um construtor, tem que utilizar ele, para não dar o problema do Spring, de utilizar o contrutor do TObject,
      sendo que existe um contrutor em qualquer nível das classes herdadas
  - Na fábrica de objetos, tem que permitir utilizar apenas construtores públicos
}

  [TestFixture]
  TInjectorTest = class
  private
    FInjector: TInjector;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure WhenRegisterAFunctionFactoryMustUseThisFactoryToCreateTheObject;
    [Test]
    procedure WhenRegisterAFunctionFactoryWithParamsMustUseThisFunctionToCreateTheObject;
    [Test]
    procedure TheResolveFunctionMustReturnTheInstanceOfTheObjectWhenCalled;
    [Test]
    procedure WhenResolveATypeWithParamsMustReturnTheInstanceOfTheObject;
    [Test]
    procedure WhenRegisterAnInstanceFactoryMustReturnThisInstanceWhenResolveTheObject;
    [Test]
    procedure WhenRegisterAFactoryInterfaceMustUseThisInterfaceToCreateTheObject;
    [Test]
    procedure WhenRegisterAClassFactoryMustRegisterAFactoryToThisType;
    [Test]
    procedure WhenDoNotFindATypeRegisteredMustRaiseAnError;
    [Test]
    procedure WhenTryToResolveATypeNotRegisteredMustFindItInTheRttiAndResolveTheType;
    [Test]
    procedure WhenTryToResolveAnInterfaceNotRegisteredMustFindInTheTypeInRttiAndResolveTheType;
    [Test]
    procedure WhenTryToRegisterTheSameFactoryMoreThenOnceCannnotRaiseAnyError;
    [Test]
    procedure WhenRegisterATypeNamedFactoryMustUseTheNamedFactoryToCreateTheType;
    [Test]
    procedure WhenRegisterAnInstanceNamedFactoryMustUseThisFactoryToResolveTheType;
    [Test]
    procedure WhenRegisterANamedFunctionFactoryMustUseThisFactoryToResolveTheType;
    [Test]
    procedure WhenRegisterANamedFunctionFactoryWithParamsMustUseThisFactoryToResolveTheType;
    [Test]
    procedure WhenFindMoreThenOneFactoryForATypeMustRaiseError;
    [Test]
    procedure WhenResolveAnInterfaceMustReturnTheInterfaceInstanceLoaded;
    [Test]
    procedure WhenResolveAllMustCreateAllTypeRegisteredForFactotySelected;
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
  public
    [Setup]
    procedure Setup;
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
  end;

  [TestFixture]
  TInstanceFactoryTest = class
  public
    [Test]
    procedure WhenCallTheFactoryConstructorMustReturnTheInstanceOfTheClass;
  end;

  [TestFixture]
  TInterfaceFactoryTest = class
  private
    FContext: TRttiContext;
  public
    [Setup]
    procedure Setup;
    [Teardown]
    procedure Teardown;
    [Test]
    procedure WhenConstructTheInterfaceMustLocateTheObjectThatImplementsTheInterface;
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

  TClassInheritedWithoutConstructor = class(TClassWithConstructor)
  private
    FEmptyProperty: Integer;
  public
    property EmptyProperty: Integer read FEmptyProperty write FEmptyProperty;
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

  IMyInterface = interface
    ['{904F4775-6482-447C-8FDA-849036C92077}']
  end;

  TMyObjectInterface = class(TInterfacedObject, IMyInterface)
  end;

  {$M-}
  TClassNotRegistered = class
  end;
  {$M+}

implementation

uses System.TypInfo, System.SysUtils, Delphi.Mock;

{ TInjectorTest }

procedure TInjectorTest.Setup;
begin
  FInjector := TInjector.Create;

  TMock.CreateInterface<IFactory>;
end;

procedure TInjectorTest.TearDown;
begin
  FInjector.Free;
end;

procedure TInjectorTest.TheResolveFunctionMustReturnTheInstanceOfTheObjectWhenCalled;
begin
  FInjector.RegisterFactory<TSimpleClass>(
    function: TSimpleClass
    begin
      Result := TSimpleClass.Create;
    end);

  var AClass := FInjector.Resolve<TSimpleClass>;

  Assert.IsNotNull(AClass);

  AClass.Free;
end;

procedure TInjectorTest.WhenDoNotFindATypeRegisteredMustRaiseAnError;
begin
  // Find a way to try to resolve an unregistered class
  Assert.IsTrue(True);
end;

procedure TInjectorTest.WhenFindMoreThenOneFactoryForATypeMustRaiseError;
begin
  FInjector.RegisterFactory<TSimpleClass>;

  FInjector.RegisterFactory<TSimpleClass>;

  FInjector.RegisterFactory<TSimpleClass>;

  Assert.WillRaise(
    procedure
    begin
      FInjector.Resolve<TSimpleClass>;
    end, EFoundMoreThenOneFactory);
end;

procedure TInjectorTest.WhenRegisterAClassFactoryMustRegisterAFactoryToThisType;
begin
  FInjector.RegisterFactory<TSimpleClass>;

  var AClass := FInjector.Resolve<TSimpleClass>;

  Assert.IsNotNull(AClass);

  AClass.Free;
end;

procedure TInjectorTest.WhenRegisterAFactoryInterfaceMustUseThisInterfaceToCreateTheObject;
begin
  var AFactory := TMock.CreateInterface<IFactory>(True);

  AFactory.Expect.Once.When.Construct(It.IsAny<TArray<TValue>>);

  FInjector.RegisterFactory<TSimpleClass>(AFactory.Instance);

  FInjector.Resolve<TSimpleClass>.Free;

  Assert.CheckExpectation(AFactory.CheckExpectations);
end;

procedure TInjectorTest.WhenRegisterAFunctionFactoryMustUseThisFactoryToCreateTheObject;
begin
  var FunctionCalled := False;

  FInjector.RegisterFactory<TSimpleClass>(
    function: TSimpleClass
    begin
      FunctionCalled := True;
      Result := nil;
    end);

  FInjector.Resolve<TSimpleClass>;

  Assert.IsTrue(FunctionCalled);
end;

procedure TInjectorTest.WhenRegisterAFunctionFactoryWithParamsMustUseThisFunctionToCreateTheObject;
begin
  var FunctionCalled := False;

  FInjector.RegisterFactory<TSimpleClass>(
    function (const Params: TArray<TValue>): TSimpleClass
    begin
      FunctionCalled := (Length(Params) = 1) and (Params[0].AsInteger = 1234);
      Result := nil;
    end);

  FInjector.Resolve<TSimpleClass>([1234]);

  Assert.IsTrue(FunctionCalled);
end;

procedure TInjectorTest.WhenRegisterANamedFunctionFactoryMustUseThisFactoryToResolveTheType;
begin
  var FunctionCalled := False;

  FInjector.RegisterFactory<TSimpleClass>('MyFactory',
    function: TSimpleClass
    begin
      FunctionCalled := True;
      Result := nil;
    end);

  FInjector.Resolve<TSimpleClass>('MyFactory');

  Assert.IsTrue(FunctionCalled);
end;

procedure TInjectorTest.WhenRegisterANamedFunctionFactoryWithParamsMustUseThisFactoryToResolveTheType;
begin
  var FunctionCalled := False;

  FInjector.RegisterFactory<TSimpleClass>('MyFactory',
    function(const Params: TArray<TValue>): TSimpleClass
    begin
      FunctionCalled := True;
      Result := nil;
    end);

  FInjector.Resolve<TSimpleClass>('MyFactory');

  Assert.IsTrue(FunctionCalled);
end;

procedure TInjectorTest.WhenRegisterAnInstanceFactoryMustReturnThisInstanceWhenResolveTheObject;
begin
  var AClass := TSimpleClass.Create;

  FInjector.RegisterFactory(AClass);

  var TheObject := FInjector.Resolve<TSimpleClass>;

  Assert.AreEqual(AClass, TheObject);

  AClass.Free;
end;

procedure TInjectorTest.WhenRegisterAnInstanceNamedFactoryMustUseThisFactoryToResolveTheType;
begin
  var AClass := TSimpleClass.Create;

  FInjector.RegisterFactory('MyFactory', AClass);

  var TheObject := FInjector.Resolve<TSimpleClass>('MyFactory');

  Assert.AreEqual(AClass, TheObject);

  AClass.Free;
end;

procedure TInjectorTest.WhenRegisterATypeNamedFactoryMustUseTheNamedFactoryToCreateTheType;
begin
  FInjector.RegisterFactory<TSimpleClass>('MyFactory');

  var AClass := FInjector.Resolve<TSimpleClass>('MyFactory');

  Assert.IsNotNull(AClass);

  AClass.Free;
end;

procedure TInjectorTest.WhenResolveAllMustCreateAllTypeRegisteredForFactotySelected;
begin
  FInjector.RegisterFactory<IMyInterface>('MyFactory',
    function: IMyInterface
    begin
      Result := nil;
    end);

  FInjector.RegisterFactory<IMyInterface>('MyFactory',
    function: IMyInterface
    begin
      Result := nil;
    end);

  FInjector.RegisterFactory<IMyInterface>('MyFactory',
    function: IMyInterface
    begin
      Result := nil;
    end);

  var ResolvedValues := FInjector.ResolveAll<IMyInterface>('MyFactory', [0]);

  Assert.AreEqual<NativeInt>(3, Length(ResolvedValues));
end;

procedure TInjectorTest.WhenResolveAnInterfaceMustReturnTheInterfaceInstanceLoaded;
begin
  FInjector.RegisterFactory<IMyInterface>;

  var MyInterface := FInjector.Resolve<IMyInterface>;

  Assert.IsNotNull(MyInterface);

  MyInterface := nil;
end;

procedure TInjectorTest.WhenResolveATypeWithParamsMustReturnTheInstanceOfTheObject;
begin
  FInjector.RegisterFactory<TSimpleClass>(
    function: TSimpleClass
    begin
      Result := TSimpleClass.Create;
    end);

  var AClass := FInjector.Resolve<TSimpleClass>([1234]);

  Assert.IsNotNull(AClass);

  AClass.Free;
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

procedure TInjectorTest.WhenTryToResolveAnInterfaceNotRegisteredMustFindInTheTypeInRttiAndResolveTheType;
begin
  Assert.WillNotRaise(
    procedure
    begin
      var AnInterface := FInjector.Resolve<IMyInterface>;

      AnInterface := nil;
    end, ETypeFactoryNotRegistered);
end;

procedure TInjectorTest.WhenTryToResolveATypeNotRegisteredMustFindItInTheRttiAndResolveTheType;
begin
  Assert.WillNotRaise(
    procedure
    begin
      var AClass := FInjector.Resolve<TSimpleClass>;

      AClass.Free;
    end, ETypeFactoryNotRegistered);
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

procedure TObjectFactoryTest.Setup;
begin
  FContext := TRttiContext.Create;
end;

procedure TObjectFactoryTest.WhenCallTheConstructMustCreateTheClassInsideTheFactory;
begin
  var Factory := TObjectFactory.Create(FContext.GetType(TSimpleClass).AsInstance) as IFactory;
  var TheObject := Factory.Construct(nil).AsObject;

  Assert.IsNotNull(TheObject);

  TheObject.Free;
end;

procedure TObjectFactoryTest.WhenCantFindAConstructorMustRaiseAnError;
begin
  var Factory := TObjectFactory.Create(FContext.GetType(TSimpleClass).AsInstance) as IFactory;

  Assert.WillRaise(
    procedure
    begin
      Factory.Construct([123]).AsObject.Free;
    end);
end;

procedure TObjectFactoryTest.WhenTheClassConstructorHasParamsThisParamsMustBePassedInTheInvokerOfTheConstuctor;
begin
  var AnObject := TObject.Create;
  var Factory := TObjectFactory.Create(FContext.GetType(TClassWithParamsInConstructor).AsInstance) as IFactory;
  var TheObject := Factory.Construct([AnObject, 1234]).AsType<TClassWithParamsInConstructor>;

  Assert.IsNotNull(TheObject);

  Assert.AreEqual(AnObject, TheObject.Param1);

  Assert.AreEqual(1234, TheObject.Param2);

  AnObject.Free;

  TheObject.Free;
end;

procedure TObjectFactoryTest.WhenTheClassHasAConstrutorMustCallThisConstructorOnTheFactory;
begin
  var Factory := TObjectFactory.Create(FContext.GetType(TClassWithConstructor).AsInstance) as IFactory;
  var TheObject := Factory.Construct(nil).AsType<TClassWithConstructor>;

  Assert.IsTrue(TheObject.TheConstructorCalled);

  TheObject.Free;
end;

procedure TObjectFactoryTest.WhenTheClassHasMoreThenOneContructorMustSelectTheConstructorByTheCountOfTheParams(ExpectParam1: Integer; ExpectParam2: String; ParamValue1: Integer; ParamValue2: String);
begin
  var Factory := TObjectFactory.Create(FContext.GetType(TClassWithThreeContructors).AsInstance) as IFactory;
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
  var Factory := TObjectFactory.Create(FContext.GetType(TClassWithConstructorWithTheSameParameterCount).AsInstance) as IFactory;
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

{ TInstanceFactoryTest }

procedure TInstanceFactoryTest.WhenCallTheFactoryConstructorMustReturnTheInstanceOfTheClass;
begin
  var AClass := TSimpleClass.Create;
  var AFactory := TInstanceFactory.Create(AClass) as IFactory;
  var TheObject := AFactory.Construct(nil).AsType<TSimpleClass>;

  Assert.AreEqual(AClass, TheObject);

  AClass.Free;
end;

{ TInterfaceFactoryTest }

procedure TInterfaceFactoryTest.Setup;
begin
  FContext := TRttiContext.Create;
end;

procedure TInterfaceFactoryTest.Teardown;
begin
  FContext.Free;
end;

procedure TInterfaceFactoryTest.WhenConstructTheInterfaceMustLocateTheObjectThatImplementsTheInterface;
begin
  var Injector := TInjector.Create;

  var Factory := TInterfaceFactory.Create(Injector, FContext.GetType(TypeInfo(IMyInterface)) as TRttiInterfaceType) as IFactory;
  var MyInterface := Factory.Construct(nil);

  Assert.IsFalse(MyInterface.IsEmpty);

  Assert.AreEqual(TMyObjectInterface, TObject(MyInterface.AsType<IMyInterface>).ClassType);

  Injector.Free;
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

end.

