# Boomer Tech FlatFileSerializer

```delphi
  TTestModel = class(TFlatFileModelBase)
  private
    fSomeNumber: integer;
    fName: string;
    fSalary: currency;
    fBirthDate: TDate;
  public
    [TFlatFileItem(2, 3, 'x', true)]
    property SomeNumber: integer read fSomeNumber write fSomeNumber;

    [TFlatFileItem(1, 40)]
    property Name: string read fName write fName;

    [TFlatFileItem(3, 10, '0', true)]
    property Salary: currency read fSalary write fSalary;

    [TFlatFileItem(4, 8)]
    property BirthDate: TDate read fBirthDate write fBirthDate;
  end;
```
