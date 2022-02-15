unit Delphi.Injection.Test;

interface

uses DUnitX.TestFramework, System.Rtti, Delphi.Injection, System.Classes;

type
{
  Testes a serem feitos:
  - Quando resolver uma classe, tem que encontrar todos os tipos esperados no contrutor da classe
  - Lançar um erro quando não encontrar todos os parâmetros do construtor da classe
  - Tem um opção de configuração para tentar achar um construtor qualquer, para construir a classe, independente do nível de herança
  - Se no nível atual não tiver um construtor tem que ir para a base da classe, e assim por diante até encontrar o construtor do TObject
  - Se tentar resolver um interface, tem que buscar na lista de tipos, qual implementa essa classe e construir a mesma
  - Injetar campos das classes, isso tem que ser via anotação
  - Permitir registrar construtores para os tipos, afim de permitir o programador decidir como a instância deve ser gerada
  - Controle de ciclo de vida do objecto (Singleton, Thread, etc...)
    * Ideia, quando o ciclo de vida por por thread, quando for requisitado para resolver algum valor dentro de um thread, abrir um outra thread que chama o WaitFor da thread corrente, e quando terminar, elimina
    as váriaveis criadas nessa thread
  - Limitar os tipos resolviveis á classes, interfaces e records?
    * Acredito que sim, por que os tipos nativos, não tem por que serem resolvidos, e no caso do records, apenas os campos podem ser resolvidos
}

  [TestFixture]
  TDelphiInjectionTest = class
  private
    FInjector: TInjector;
  public
    [SetupFixture]
    procedure SetupFixture;
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure WhenResolveAnClassMustCreateTheClassAndReturnTheInstance;
    [Test]
    procedure WhenTheClassHasItsOwnContrutctorThisMustBeCalledInTheResolver;
    [Test]
    procedure WhenTheContructorHasParamsAndTheParamIsPassedInTheResolverMustCreateTheClassWithThisParams;
    [TestCase('No param', '123,abc')]
    [TestCase('One param', '456,abc,456')]
    [TestCase('Two params', '789,def,789,def')]
    procedure WhenTheClassHasMoreThenOneContructorMustSelectTheConstructorByTheTypeOfThePassedParams(ExpectParam1: Integer; ExpectParam2: String; ParamValue1: Integer; ParamValue2: String);
    [Test]
    procedure WhenAClassDoesntHaveAConstructorMustCreateTheClassFromTheBaseClassConstructor;
    [Test]
    procedure WhenTheConstructorsOfTheClassHasTheSameParamCountMustCreateTheClassByTheSignatureOfTypeOfTheParamsOfTheConstructor;
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

implementation

uses System.TypInfo, System.SysUtils;

{ TDelphiInjectionTest }

procedure TDelphiInjectionTest.Setup;
begin
  FInjector := TInjector.Create;
end;

procedure TDelphiInjectionTest.SetupFixture;
begin
  var Context := TRttiContext.Create;

  for var RttiType in Context.GetTypes do
    RttiType.GetMethods;

  Context.Free;
end;

procedure TDelphiInjectionTest.TearDown;
begin
  FInjector.Free;
end;

procedure TDelphiInjectionTest.WhenAClassDoesntHaveAConstructorMustCreateTheClassFromTheBaseClassConstructor;
begin
  var AClass := FInjector.Resolve<TClassInheritedWithoutConstructor>;

  Assert.IsNotNull(AClass);

  Assert.AreEqual(0, AClass.EmptyProperty);

  AClass.Free;
end;

procedure TDelphiInjectionTest.WhenResolveAnClassMustCreateTheClassAndReturnTheInstance;
begin
  var AClass := FInjector.Resolve<TSimpleClass>;

  Assert.IsNotNull(AClass);

  AClass.Free;
end;

procedure TDelphiInjectionTest.WhenTheClassHasItsOwnContrutctorThisMustBeCalledInTheResolver;
begin
  var AClass := FInjector.Resolve<TClassWithConstructor>;

  Assert.IsNotNull(AClass);

  Assert.IsTrue(AClass.TheConstructorCalled);

  AClass.Free;
end;

procedure TDelphiInjectionTest.WhenTheClassHasMoreThenOneContructorMustSelectTheConstructorByTheTypeOfThePassedParams(ExpectParam1: Integer; ExpectParam2: String; ParamValue1: Integer; ParamValue2: String);
begin
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

  var AClass := FInjector.Resolve<TClassWithThreeContructors>(Params);

  Assert.IsNotNull(AClass);

  Assert.AreEqual(ExpectParam1, AClass.Param1);

  Assert.AreEqual(ExpectParam2, AClass.Param2);

  AClass.Free;
end;

procedure TDelphiInjectionTest.WhenTheConstructorsOfTheClassHasTheSameParamCountMustCreateTheClassByTheSignatureOfTypeOfTheParamsOfTheConstructor;
begin
  Assert.IsTrue(False, 'Continuando daqui...');
end;

procedure TDelphiInjectionTest.WhenTheContructorHasParamsAndTheParamIsPassedInTheResolverMustCreateTheClassWithThisParams;
begin
  var ObjectParam := TObject.Create;

  var AClass := FInjector.Resolve<TClassWithParamsInConstructor>([ObjectParam, 1234]);

  Assert.IsNotNull(AClass);

  Assert.AreEqual(ObjectParam, AClass.Param1);

  Assert.AreEqual(1234, AClass.Param2);

  AClass.Free;

  ObjectParam.Free;
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

end.

