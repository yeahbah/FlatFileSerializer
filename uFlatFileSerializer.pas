unit uFlatFileSerializer;

interface

uses
  uFlatFileDocument, uFlatFileModel, Classes, Spring.Collections, Generics.Collections,
  Rtti, uFlatFileAttributes, Generics.Defaults, SysUtils;


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

  EInvalidRecordParentClass = class(Exception)
  public

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
//      extract individual models
//        recordList := prop.GetValue(Pointer(aFlatFileDocument)).AsType<IList<TFlatFileModelBase>>();
//        attrList.Add(TPropertyMap.Create(recordList, TFlatFileRecordListAttribute(attr), prop))
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

    if prop.RecordAttribute is TFlatFileRecordListAttribute then
    begin

    end
    else
    begin
      value := prop.ModelInstance.ToString() + chr(13) + chr(10);
      aOutputStream.WriteString(value);
    end;
  end;

end;

end.
