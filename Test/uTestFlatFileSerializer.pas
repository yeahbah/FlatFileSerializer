unit uTestFlatFileSerializer;

interface
uses
  DUnitX.TestFramework, uFlatFileDocument, uFlatFileModel, uFlatFileSerializer,
  uFlatFileAttributes, Spring.Collections, SysUtils, Classes, uTestModel;

type

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
var
  serializer: TFlatFileSerializer<TSimpleDocument>;
  stringStream: TStringStream;
  outputDocument: TSimpleDocument;
  peeps: TArray<TPersonModel>;
begin
  serializer := TFlatFileSerializer<TSimpleDocument>.Create;
  try
    stringStream := TStringStream.Create;
    try
      serializer.Serialize(stringStream, fSimpleDocument);
      outputDocument := TSimpleDocument.Create;
      try
        serializer.Deserialize(stringStream, outputDocument);
        peeps := outputDocument.People.ToArray;
        Assert.IsNotNull(outputDocument.Header);
        Assert.IsNotNull(outputDocument.ControlRecord);
        with outputDocument do
        begin
          Assert.AreEqual('H', Header.Identifier);
          Assert.AreEqual('X1', Header.SomeCode);
          Assert.AreEqual(EncodeDateTime(2021, 3, 15, 22, 15, 10, 0), Header.Timestamp);
          Assert.AreEqual('', Header.Blank);

          Assert.AreEqual(3, People.Count);
          with People[0] do
          begin
            Assert.AreEqual('LOYD CHRISTMAS', Name);
            Assert.AreEqual(22, SomeNumber);
            Assert.AreEqual(EncodeDate(1985, 12, 25), BirthDate);
            Assert.IsTrue(2.99 = Salary);
          end;

          with People[1] do
          begin
            Assert.AreEqual('HARRY DUNNE', Name);
            Assert.AreEqual(23, SomeNumber);
            Assert.AreEqual(EncodeDate(1984, 12, 26), BirthDate);
            Assert.IsTrue(101010.99 = Salary);
          end;

          with People[2] do
          begin
            Assert.AreEqual('MARY SAMSONITE', Name);
            Assert.AreEqual(24, SomeNumber);
            Assert.AreEqual(EncodeDate(1982, 10, 10), BirthDate);
            Assert.IsTrue(1010101 = Salary);
          end;

          Assert.AreEqual(3, ControlRecord.TotalPeople);
          Assert.AreEqual('C', ControlRecord.Identifier);
          Assert.AreEqual('', ControlRecord.Blank);
        end;
      finally
        outputDocument.Free;
      end;
    finally
      stringStream.Free;
    end;
  finally
    serializer.Free;
  end;
end;

procedure TFlatFileSerializerTest.TestSerialize;
var
  serializer: TFlatFileSerializer<TSimpleDocument>;
  stringStream: TStringStream;
  s: TStringList;
  header: THeaderModel;
  person: TPersonModel;
  control: TControlRecord;
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
        Assert.AreEqual('H', header.Identifier);
        Assert.AreEqual('X1', header.SomeCode);
        Assert.AreEqual(EncodeDateTime(2021, 3, 15, 22, 15, 10, 0), header.Timestamp);
        Assert.AreEqual('', header.Blank);

        // list of people test
        person := TPersonModel.Create;
        person.SetFromString(s[1]);
        Assert.AreEqual('P', person.Identifier);
        Assert.AreEqual('LOYD CHRISTMAS', person.Name);
        Assert.IsTrue(2.99 = person.Salary);
        Assert.AreEqual(22, person.SomeNumber);
        Assert.AreEqual(EncodeDate(1985, 12, 25), person.BirthDate);

        // control record test
        control := TControlRecord.Create;
        control.SetFromString(s[s.Count-1]);
        Assert.AreEqual('C', control.Identifier);
        Assert.AreEqual(3, control.TotalPeople);
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
