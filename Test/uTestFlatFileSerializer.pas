unit uTestFlatFileSerializer;

interface
uses
  DUnitX.TestFramework, uFlatFileDocument, uFlatFileModel, uFlatFileSerializer,
  uFlatFileAttributes, Spring.Collections, SysUtils, Classes;

type
  TPersonModel = class(TFlatFileModelBase)
  private
    fSomeNumber: integer;
    fName: string;
    fSalary: currency;
    fBirthDate: TDate;
    fIdentifier: string;
  public
    [TFlatFileRecordIdentifier('P')]
    property Identifier: string read fIdentifier write fIdentifier;

    [TFlatFileItem(2, 3, TSpaceFill.sfSpace, true)]
    property SomeNumber: integer read fSomeNumber write fSomeNumber;

    [TFlatFileItem(1, 40)]
    property Name: string read fName write fName;

    [TFlatFileItem(3, 10, TSpaceFill.sfZero, true)]
    property Salary: currency read fSalary write fSalary;

    [TFlatFileItem(4, 8)]
    property BirthDate: TDate read fBirthDate write fBirthDate;
  end;

  THeaderModel = class(TFlatFileModelBase)
  private
    fSomeCode: string;
    fTimestamp: TDateTime;
    fBlank: string;
  public
    [TFlatFileItem(1, 2)]
    property SomeCode: string read fSomeCode write fSomeCode;

    [TFlatFileItem(2, 15)]
    property Timestamp: TDateTime read fTimestamp write fTimestamp;

    [TFlatFileItem(3, 44)]
    property Blank: string read fBlank write fBlank;
  end;

  TControlRecord = class(TFlatFileModelBase)
  private
    fTotalPeople: integer;
    fBlank: string;
  public
    [TFlatFileItem(1, 12, TSpaceFill.sfZero, true)]
    property TotalPeople: integer read fTotalPeople write fTotalPeople;

    [TFlatFileItem(2, 49)]
    property Blank: string read fBlank write fBlank;
  end;

  TSimpleDocument = class(TFlatFileDocumentBase)
  private
    fPeople: IList<TPersonModel>;
    fHeader: THeaderModel;
    fControlRecord: TControlRecord;
  public
    [TFlatFileRecord(1)]
    property Header: THeaderModel read fHeader write fHeader;

    [TFlatFileRecordList(2)]
    property People: IList<TPersonModel> read fPeople write fPeople;

    [TFlatFileRecord(3)]
    property ControlRecord: TControlRecord read fControlRecord write fControlRecord;
  end;

  [TestFixture]
  TFlatFileSerializerTest = class
  private
    fSimpleDocument: TSimpleDocument;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestSerialize();

    [Test]
    procedure TestDeserialize();
  end;

implementation

uses
  DateUtils;

{ TFlatFileSerializerTest }

procedure TFlatFileSerializerTest.Setup;
var
  person: TPersonModel;
begin
  fSimpleDocument := TSimpleDocument.Create;
  fSimpleDocument.People := TCollections.CreateList<TPersonModel>();
  fSimpleDocument.Header := THeaderModel.Create;
  fSimpleDocument.ControlRecord := TControlRecord.Create;

  with fSimpleDocument.Header do
  begin
    SomeCode := 'X1';
    Timestamp := EncodeDateTime(2021, 3, 15, 22, 15, 10, 0);
    Blank := '';
  end;

  person := TPersonModel.Create;
  person.Name := 'LOYD CHRISTMAS';
  person.Salary := 2.99;
  person.BirthDate := EncodeDate(1985, 12, 25);
  person.SomeNumber := 22;
  fSimpleDocument.People.Add(person);

  person := TPersonModel.Create;
  person.Name := 'HARRY DUNNE';
  person.Salary := 101010.99;
  person.BirthDate := EncodeDate(1984, 12, 26);
  person.SomeNumber := 23;
  fSimpleDocument.People.Add(person);

  person := TPersonModel.Create;
  person.Name := 'MARY SAMSONITE';
  person.Salary := 1010101;
  person.BirthDate := EncodeDate(1982, 10, 10);
  person.SomeNumber := 24;
  fSimpleDocument.People.Add(person);

  fSimpleDocument.ControlRecord.TotalPeople := fSimpleDocument.People.Count;
end;

procedure TFlatFileSerializerTest.TearDown;
begin
  fSimpleDocument.Free;
end;

procedure TFlatFileSerializerTest.TestDeserialize;
begin

end;

procedure TFlatFileSerializerTest.TestSerialize;
var
  serializer: TFlatFileSerializer<TSimpleDocument>;
  document: TSimpleDocument;
  stringStream: TStringStream;
  s: TStringList;
  header: THeaderModel;
begin
  serializer := TFlatFileSerializer<TSimpleDocument>.Create();
  try
    stringStream := TStringStream.Create;
    try
      serializer.Serialize(stringStream, fSimpleDocument);
      s := TStringList.Create;
      try
        stringStream.Position := 0;
        s.LoadFromStream(stringStream);

        // header test
        header := THeaderModel.Create;
        header.SetFromString(s[0]);
        Assert.AreEqual('X1', header.SomeCode);
        Assert.AreEqual(EncodeDateTime(2021, 3, 15, 22, 15, 10, 0), header.Timestamp);
        Assert.AreEqual('', header.Blank);

        // control record test

        // list of people test


      finally
        s.Free;
      end;
    finally
      stringStream.Free;
    end;
  finally
    serializer.Free;
  end;

end;

initialization
  TDUnitX.RegisterTestFixture(TFlatFileSerializerTest);

end.
