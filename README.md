# Boomer Tech FlatFileSerializer

```delphi
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
```
