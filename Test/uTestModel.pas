unit uTestModel;

interface

uses
  uFlatFileAttributes, uFlatFileModel, uFlatFileDocument, Spring.Collections;

type
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

  THeaderModel = class(TFlatFileModelBase)
  private
    fSomeCode: string;
    fTimestamp: TDateTime;
    fBlank: string;
    fIdentifier: string;
  public
    [TFlatFileItem(1, 1, 'H')]
    property Identifier: string read fIdentifier write fIdentifier;

    [TFlatFileItem(2, 2)]
    property SomeCode: string read fSomeCode write fSomeCode;

    [TFlatFileItem(3, 15)]
    property Timestamp: TDateTime read fTimestamp write fTimestamp;

    [TFlatFileItem(4, 44)]
    property Blank: string read fBlank write fBlank;
  end;

  TControlRecord = class(TFlatFileModelBase)
  private
    fTotalPeople: integer;
    fBlank: string;
    fIdentifier: string;
  public
    [TFlatFileItem(1, 1, 'C')]
    property Identifier: string read fIdentifier write fIdentifier;

    [TFlatFileItem(2, 12, TSpaceFill.sfZero, true)]
    property TotalPeople: integer read fTotalPeople write fTotalPeople;

    [TFlatFileItem(3, 49)]
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

    [TFlatFileRecordListAttribute(2)]
    property People: IList<TPersonModel> read fPeople write fPeople;

    [TFlatFileRecord(3)]
    property ControlRecord: TControlRecord read fControlRecord write fControlRecord;

    procedure CreateLists; override;
  end;



  TTransmitterModel = class;
  T1099DocumentModel = class;
  TPayerModel = class;
  TPayeeModel = class;

  T1099DocumentModel = class(TFlatFileDocumentBase)
  private
    fTransmitter: TTransmitterModel;
    fPayer: TPayerModel;
    fPayeeList: IList<TPayeeModel>;
  public
    [TFlatFileRecord(1)]
    property Transmitter: TTransmitterModel read fTransmitter write fTransmitter;

    [TFlatFileRecord(2)]
    property Payer: TPayerModel read fPayer write fPayer;

    [TFlatFileRecord(3)]
    property PayeeList: IList<TPayeeModel> read fPayeeList write fPayeeList;

    procedure CreateLists; override;
  end;

  TTransmitterModel = class(TFlatFileModelBase)
  private
    fRecordType: string;
    fPaymentYear: string;
    fPriorYearDataIndicator: string;
    fTrasmitterTin: string;
    fTrasmitterControlCode: string;
    fBlank1: string;
    fForeignEntityIndicator: string;
    fTransmitterName1: string;
    fTransmitterName2: string;
    fCompanyName1: string;
    fCompanyName2: string;
    fCompanyMailingAddress: string;
    fCompanyCity: string;
    fCompanyState: string;
    fCompanyZipCode: string;
    fBlank2: string;
    fTotalNumberOfPayees: string;
    fContactName: string;
    fContactTelNumber: string;
    fContactEmailAddress: string;
    fBlank3: string;
    fRecordSequenceNumber: string;
    fBlank4: string;
    fVendorIndicator: string;
    fVendorName: string;
    fVendorMailingAddress: string;
    fVendorCity: string;
    fVendorState: string;
    fVendorZipCode: string;
    fVendorContactName: string;
    fVendorContactTelNumber: string;
    fBlank5: string;
    fVendorForeignEntityIndicator: string;
    fBlank6: string;
    fBlank7: string;
    fTestFileIndicator: string;
    fVendorTelExt: string;
  public
    [TFlatFileItem(1, 1)]
    property RecordType: string read fRecordType write fRecordType;

    [TFlatFileItem(2, 4)]
    property PaymentYear: string read fPaymentYear write fPaymentYear;

    [TFlatFileItem(3, 1)]
    property PriorYearDataIndicator: string read fPriorYearDataIndicator write fPriorYearDataIndicator;

    [TFlatFileItem(4, 9)]
    property TrasmitterTin: string read fTrasmitterTin write fTrasmitterTin;

    [TFlatFileItem(5, 5)]
    property TrasmitterControlCode: string read fTrasmitterControlCode write fTrasmitterControlCode;

    [TFlatFileItem(6, 7)]
    property Blank1: string read fBlank1 write fBlank1;

    [TFlatFileItem(7, 1)]
    property TestFileIndicator: string read fTestFileIndicator write fTestFileIndicator;

    [TFlatFileItem(8, 1)]
    property ForeignEntityIndicator: string read fForeignEntityIndicator write fForeignEntityIndicator;

    [TFlatFileItem(9, 40)]
    property TransmitterName1: string read fTransmitterName1 write fTransmitterName1;

    [TFlatFileItem(10, 40)]
    property TransmitterName2: string read fTransmitterName2 write fTransmitterName2;

    [TFlatFileItem(11, 40)]
    property CompanyName1: string read fCompanyName1 write fCompanyName1;

    [TFlatFileItem(12, 40)]
    property CompanyName2: string read fCompanyName2 write fCompanyName2;

    [TFlatFileItem(13, 40)]
    property CompanyMailingAddress: string read fCompanyMailingAddress write fCompanyMailingAddress;

    [TFlatFileItem(14, 40)]
    property CompanyCity: string read fCompanyCity write fCompanyCity;

    [TFlatFileItem(15, 2)]
    property CompanyState: string read fCompanyState write fCompanyState;

    [TFlatFileItem(16, 9)]
    property CompanyZipCode: string read fCompanyZipCode write fCompanyZipCode;

    [TFlatFileItem(17, 15)]
    property Blank2: string read fBlank2 write fBlank2;

    [TFlatFileItem(18, 8)]
    property TotalNumberOfPayees: string read fTotalNumberOfPayees write fTotalNumberOfPayees;

    [TFlatFileItem(19, 40)]
    property ContactName: string read fContactName write fContactName;

    [TFlatFileItem(20, 15)]
    property ContactTelNumber: string read fContactTelNumber write fContactTelNumber;

    [TFlatFileItem(21, 50)]
    property ContactEmailAddress: string read fContactEmailAddress write fContactEmailAddress;

    [TFlatFileItem(22, 91)]
    property Blank3: string read fBlank3 write fBlank3;

    [TFlatFileItem(23, 8)]
    property RecordSequenceNumber: string read fRecordSequenceNumber write fRecordSequenceNumber;

    [TFlatFileItem(24, 10)]
    property Blank4: string read fBlank4 write fBlank4;

    [TFlatFileItem(25, 1)]
    property VendorIndicator: string read fVendorIndicator write fVendorIndicator;

    [TFlatFileItem(26, 40)]
    property VendorName: string read fVendorName write fVendorName;

    [TFlatFileItem(27, 40)]
    property VendorMailingAddress: string read fVendorMailingAddress write fVendorMailingAddress;

    [TFlatFileItem(28, 40)]
    property VendorCity: string read fVendorCity write fVendorCity;

    [TFlatFileItem(29, 2)]
    property VendorState: string read fVendorState write fVendorState;

    [TFlatFileItem(30, 9)]
    property VendorZipCode: string read fVendorZipCode write fVendorZipCode;

    [TFlatFileItem(31, 40)]
    property VendorContactName: string read fVendorContactName write fVendorContactName;

    [TFlatFileItem(32, 15)]
    property VendorContactTelNumber: string read fVendorContactTelNumber write fVendorContactTelNumber;

    [TFlatFileItem(33, 15)]
    property VendorTelExt: string read fVendorTelExt write fVendorTelExt;

    [TFlatFileItem(34, 35)]
    property Blank5: string read fBlank5 write fBlank5;

    [TFlatFileItem(35, 1)]
    property VendorForeignEntityIndicator: string read fVendorForeignEntityIndicator write fVendorForeignEntityIndicator;

    [TFlatFileItem(36, 8)]
    property Blank6: string read fBlank6 write fBlank6;

    [TFlatFileItem(37, 2)]
    property Blank7: string read fBlank7 write fBlank7;
//    function ToString: string; override;
  end;

  TPayerModel = class(TFlatFileModelBase)

  end;

  TPayeeModel = class(TFlatFileModelBase)

  end;

implementation

uses
  SysUtils;

procedure T1099DocumentModel.CreateLists;
begin
  PayeeList := TCollections.CreateList<TPayeeModel>;
end;

{ TSimpleDocument }

procedure TSimpleDocument.CreateLists;
begin
  People := TCollections.CreateList<TPersonModel>;
  People.Add(TPersonModel.Create);
end;

end.
