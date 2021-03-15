unit uTestFlatFileModel;

interface
uses
  DUnitX.TestFramework;

type

  [TestFixture]
  TFlatFileModelTest = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    // Sample Methods
    // Simple single Test
//    [Test]
//    procedure Test1;
//    // Test with TestCase Attribute to supply parameters.
//    [Test]
//    [TestCase('TestA','1,2')]
//    [TestCase('TestB','3,4')]
//    procedure Test2(const AValue1 : Integer;const AValue2 : Integer);

    [Test]
    procedure TestToString;

    [Test]
    procedure TestReadFromString;
  end;


implementation

uses
  uFlatFileModel, uFlatFileAttributes, SysUtils;

type
  TTestModel = class(TFlatFileModelBase)
  private
    fSomeNumber: integer;
    fName: string;
    fSalary: currency;
    fBirthDate: TDate;
  public
    [TFlatFileItem(2, 3, TSpaceFill.sfSpace, true)]
    property SomeNumber: integer read fSomeNumber write fSomeNumber;

    [TFlatFileItem(1, 40)]
    property Name: string read fName write fName;

    [TFlatFileItem(3, 10, TSpaceFill.sfZero, true)]
    property Salary: currency read fSalary write fSalary;

    [TFlatFileItem(4, 8)]
    property BirthDate: TDate read fBirthDate write fBirthDate;
  end;


procedure TFlatFileModelTest.Setup;
begin
end;

procedure TFlatFileModelTest.TearDown;
begin
end;

procedure TFlatFileModelTest.TestReadFromString;
var
  testModel: TTestModel;
  str: string;
begin
  testModel := TTestModel.Create;
  try
    str := 'Don Juan Facundo                         10002500007519951231';
    testModel.SetFromString(str);
    Assert.AreEqual('Don Juan Facundo', testModel.Name);
    Assert.AreEqual(10, testModel.SomeNumber);
    Assert.IsTrue(250000.75 = testModel.Salary);
    Assert.AreEqual(EncodeDate(1995, 12, 31), testModel.BirthDate);
  finally
    testModel.Free;
  end;
end;

procedure TFlatFileModelTest.TestToString;
var
  testModel: TTestModel;
  value, expected: string;
begin
  testModel := TTestModel.Create;
  try
    testModel.SomeNumber := 10;
    testModel.Name := 'Don Juan Facundo';
    testModel.Salary := 250000.75;
    testModel.BirthDate := EncodeDate(1995, 12, 31);
    value := testModel.ToString();
    expected := 'Don Juan Facundo                         10002500007519951231';
    Assert.AreEqual(expected, value);
    Assert.AreEqual(testModel.TotalSize, expected.Length);
  finally
    testModel.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TFlatFileModelTest);


end.
