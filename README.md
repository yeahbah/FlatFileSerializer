# Boomer Tech FlatFileSerializer

```delphi
  TPersonModel = class(TFlatFileModelBase)
  private
    fSomeNumber: integer;
    fName: string;
    fSalary: currency;
    fBirthDate: TDate;
    fIdentifier: string;
  public
    [TFlatFileItem(1, 1, 'P')]
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

  TSimpleDocument = class(TFlatFileDocumentBase)
  private
    fPeople: IList<TPersonModel>;
    fHeader: THeaderModel;
    fControlRecord: TControlRecord;
  public
    [TFlatFileRecord(1)]
    property Header: THeaderModel read fHeader write fHeader;

    [TFlatFileRecordListAttribute(2)]
    property People: IList<TPersonModel> read fPeople write fPeople;

    [TFlatFileRecord(3)]
    property ControlRecord: TControlRecord read fControlRecord write fControlRecord;

  end;
  
  serializer := TFlatFileSerializer<TSimpleDocument>.Create;
  serializer.Serialize(stringStreamm, simpleDocument);
  stringStream.SaveToFile('flatfile.txt');
  
  stringStream.LoadFromFile('flatfile.txt');
  serializer.Deserialize(stringStream, simpleDocument);
```
