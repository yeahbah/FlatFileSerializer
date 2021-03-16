unit uFlatFileSerializer;

interface

uses
  uFlatFileDocument, uFlatFileModel, Classes, Spring.Collections, Generics.Collections,
  Rtti, uFlatFileAttributes, Generics.Defaults, SysUtils, uFlatFileExceptions, Spring;


type
  TPropertyMap = record
  public
    ModelInstance: TFlatFileModelBase;
    RecordAttribute: TFlatFileRecordAttribute;
    RecordProperty: TRttiProperty;
    constructor Create(aModelInstance: TFlatFileModelBase; aRecordAttribute: TFlatFileRecordAttribute; aRecordProperty: TRttiProperty);
  end;

  TFlatFileSerializer<T: TFlatFileDocumentBase> = class
  private
    function GetPropertyMap(aFlatFileDocument: T): TArray<TPropertyMap>;
  public
    procedure Serialize(aOutputStream: TStringStream; aFlatFileDocument: T);
    procedure Deserialize(aInputStream: TStringStream; out aResult: T);
  end;

implementation

{ TPropertyMap }

constructor TPropertyMap.Create(aModelInstance: TFlatFileModelBase;
  aRecordAttribute: TFlatFileRecordAttribute; aRecordProperty: TRttiProperty);
begin
  ModelInstance := aModelInstance;
  RecordAttribute := aRecordAttribute;
  RecordProperty := aRecordProperty;
end;

{ TFlatFileSerizalier<T> }

procedure TFlatFileSerializer<T>.Deserialize(aInputStream: TStringStream;
  out aResult: T);
begin

end;

function TFlatFileSerializer<T>.GetPropertyMap(
  aFlatFileDocument: T): TArray<TPropertyMap>;
var
  ctx: TRttiContext;
  objectType: TRttiType;
  prop: TRttiProperty;
  attrList: IList<TPropertyMap>;
  attr: TCustomAttribute;
  value: TFlatFileModelBase;
  recordList: IList<TFlatFileModelBase>;
  recordItem: TFlatFileModelBase;
begin
  ctx := TRttiContext.Create;
  objectType := ctx.GetType(T);
  attrList := TCollections.CreateList<TPropertyMap>();

  for prop in objectType.GetProperties() do
  begin
    for attr in prop.GetAttributes() do
    begin
      if attr is TFlatFileRecordListAttribute then
      begin
        // expand the list
        recordList := IList<TFlatFileModelBase>(prop.GetValue(Pointer(aFlatFileDocument)).AsPointer);
        for recordItem in recordList do
        begin
          attrList.Add(TPropertyMap.Create(recordItem, TFlatFileRecordAttribute(attr), prop))
        end;
      end
      else
      if attr is TFlatFileRecordAttribute then
      begin
        value := prop.GetValue(Pointer(aFlatFileDocument)).AsType<TFlatFileModelBase>();
        attrList.Add(TPropertyMap.Create(value,
          TFlatFileRecordAttribute(attr), prop));
      end;

    end;
  end;

  result := attrList.ToArray();
  TArray.Sort<TPropertyMap>(result,
    TDelegatedComparer<TPropertyMap>.Create(
      function (const left, right: TPropertyMap): integer
      begin
        result := left.RecordAttribute.Order - right.RecordAttribute.Order;
      end));


end;

procedure TFlatFileSerializer<T>.Serialize(aOutputStream: TStringStream;
  aFlatFileDocument: T);
var
  properties: TArray<TPropertyMap>;
  prop: TPropertyMap;
  flatFileModel: TFlatFileModelBase;
  value: string;
begin
  aOutputStream.Position := 0;
  properties := GetPropertyMap(aFlatFileDocument);
  for prop in properties do
  begin
    // must be child of TFlatFileModelBase
    if not (prop.ModelInstance is TFlatFileModelBase) then
      raise EInvalidRecordParentClass.CreateFmt('%s must be a descendant of TFlatFileModelBase', [prop.RecordProperty.ClassName]);

      value := prop.ModelInstance.ToString() + chr(13) + chr(10);
      aOutputStream.WriteString(value);

  end;

end;

end.
