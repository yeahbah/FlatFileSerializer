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

    [Test]
    procedure TestToString;

    [Test]
    procedure TestReadFromString;

    [Test]
    procedure TestTryToReadIncorrectString;

    [Test]
    procedure TestIdentifierIsSomewhereInTheString;

    [Test]
    procedure TestRecordIdentifierException;

    [Test]
    procedure TestRecordSizeMismatchException;

    [Test]
    procedure TestMultipleRecordIdentifierException;
  end;


implementation

uses
  uFlatFileModel, uFlatFileAttributes, SysUtils, uFlatFileExceptions;

type
  TTestModel = class(TFlatFileModelBase)
  private
    fSomeNumber: integer;
    fName: string;
    fSalary: currency;
    fBirthDate: TDate;
    fIdentifier: string;
  public
    constructor Create;
    [TFlatFileItem(1, 1, 'T')]
    property Identifier: string read fIdentifier write fIdentifier;

    [TFlatFileItem(2, 40)]
    property Name: string read fName write fName;

    [TFlatFileItem(3, 3, TSpaceFill.sfSpace, true)]
    property SomeNumber: integer read fSomeNumber write fSomeNumber;

    [TFlatFileItem(4, 10, TSpaceFill.sfZero, true)]
    property Salary: currency read fSalary write fSalary;

    [TFlatFileItem(5, 8)]
    property BirthDate: TDate read fBirthDate write fBirthDate;
  end;

  TTestModelNoIdentifier = class(TFlatFileModelBase)
  private
    fName: string;
    fSomeNumber: integer;
  public
    [TFlatFileItem(1, 40)]
    property Name: string read fName write fName;

    [TFlatFileItem(2, 3, TSpaceFill.sfSpace, true)]
    property SomeNumber: integer read fSomeNumber write fSomeNumber;

  end;

  TTestMultipleIdentifier = class(TFlatFileModelBase)
  private
    fName: string;
    fSomeNumber: integer;
    fIdentifier: string;
  public
    [TFlatFileItem(1, 1, 'T')]
    property Identifier: string read fIdentifier write fIdentifier;

    [TFlatFileItem(2, 40, 'X')]
    property Name: string read fName write fName;

    [TFlatFileItem(3, 3, TSpaceFill.sfSpace, true)]
    property SomeNumber: integer read fSomeNumber write fSomeNumber;
  end;

  TTestIdentifier = class(TFlatFileModelBase)
  private
    fName: string;
    fSomeNumber: integer;
    fIdentifier: string;
  public
    [TFlatFileItem(1, 40)]
    property Name: string read fName write fName;

    [TFlatFileItem(2, 3, 'T')]
    property Identifier: string read fIdentifier write fIdentifier;

    [TFlatFileItem(3, 3, TSpaceFill.sfSpace, true)]
    property SomeNumber: integer read fSomeNumber write fSomeNumber;
  end;

procedure TFlatFileModelTest.Setup;
begin
end;

procedure TFlatFileModelTest.TearDown;
begin
end;

procedure TFlatFileModelTest.TestIdentifierIsSomewhereInTheString;
var
  testModel: TTestIdentifier;
  str: string;
begin
  testModel := TTestIdentifier.Create;
  try
    // identifier is not the first property
    str := 'Don Juan Facundo                        T    1';
    testModel.SetFromString(str);
    Assert.AreEqual('T', testModel.Identifier);
    Assert.AreEqual('Don Juan Facundo', testModel.Name);
    Assert.AreEqual(1, testModel.SomeNumber);
  finally
    testModel.Free;
  end;

end;

procedure TFlatFileModelTest.TestMultipleRecordIdentifierException;
var
  testModel: TTestMultipleIdentifier;
begin
  testModel := TTestMultipleIdentifier.Create;
  try
    testModel.Name := 'Test';
    testModel.SomeNumber := 1;
    Assert.WillRaise(procedure
      begin
        testModel.ToString();
      end, EMultipleRecordIdentifier);
  finally
    testModel.Free;
  end;

end;

procedure TFlatFileModelTest.TestReadFromString;
var
  testModel: TTestModel;
  str: string;
begin
  testModel := TTestModel.Create;
  try
    str := 'TDon Juan Facundo                         10002500007519951231';
    testModel.SetFromString(str);
    Assert.AreEqual('Don Juan Facundo', testModel.Name);
    Assert.AreEqual(10, testModel.SomeNumber);
    Assert.IsTrue(250000.75 = testModel.Salary);
    Assert.AreEqual(EncodeDate(1995, 12, 31), testModel.BirthDate);
  finally
    testModel.Free;
  end;
end;

procedure TFlatFileModelTest.TestRecordIdentifierException;
var
  testModel: TTestModelNoIdentifier;
begin
  testModel := TTestModelNoIdentifier.Create;
  try
    testModel.Name := 'Test';
    testModel.SomeNumber := 1;
    Assert.WillRaise(procedure
      begin
        testModel.ToString();
      end, EUndefinedRecordIdentifier);
  finally
    testModel.Free;
  end;
end;

procedure TFlatFileModelTest.TestRecordSizeMismatchException;
var
  testModel: TTestModel;
  str: string;
begin
  testModel := TTestModel.Create;
  try
    str := 'Don Juan Facundo                         10002500007519951231';
    Assert.WillRaise(procedure
      begin
        testModel.SetFromString(str);
      end, ERecordSizeMismatch);
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
    testModel.Identifier := 'X'; // this is the wrong value but will get corrected internally
    testModel.SomeNumber := 10;
    testModel.Name := 'Don Juan Facundo';
    testModel.Salary := 250000.75;
    testModel.BirthDate := EncodeDate(1995, 12, 31);
    value := testModel.ToString();

    //RecordIdentifier is internally set
    //No need to explicitly set it
    //    testModel.Identifier := 'T'
    expected := 'TDon Juan Facundo                         10002500007519951231';
    Assert.AreEqual(expected, value);
    Assert.AreEqual(testModel.TotalSize, expected.Length);
  finally
    testModel.Free;
  end;
end;

procedure TFlatFileModelTest.TestTryToReadIncorrectString;
var
  testModel: TTestModel;
  str: string;
begin
  testModel := TTestModel.Create;
  try
    // identifier is expected to be T should be the first char of the string
    str := 'XDon Juan Facundo                         10002500007519951231';
    testModel.SetFromString(str);
    Assert.AreEqual('', testModel.Name);
    Assert.AreEqual(0, testModel.SomeNumber);
    Assert.IsTrue(0 = testModel.Salary);
  finally
    testModel.Free;
  end;

end;

{ TTestModel }

constructor TTestModel.Create;
begin
  fSalary := 0;
  fSomeNumber := 0;
  fName := '';
end;

initialization
  TDUnitX.RegisterTestFixture(TFlatFileModelTest);


end.
