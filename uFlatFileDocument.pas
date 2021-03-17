unit uFlatFileDocument;

interface

type
  TFlatFileDocumentBase = class abstract
  public
    // generic lists cannot be created at runtime
    // let me know if you know a better way
    procedure CreateLists; virtual; abstract;
  end;

implementation

end.
