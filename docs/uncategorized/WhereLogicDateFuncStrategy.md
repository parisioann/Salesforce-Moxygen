# WhereLogicDateFuncStrategy Class

This class is responsible for handling date functions in the WHERE clause

**Since** 

11/28/2024

**Author** Zackary Frazier

**Implements**

[IWhereLogicComparisonStrategy](IWhereLogicComparisonStrategy.md)

## Methods
### `getFieldValue(record, fieldNode)`

Get the field value from the record when the field node is for a date function

#### Signature
```apex
public WhereLogicComparisonResults getFieldValue(SObject record, Node fieldNode)
```

#### Parameters
| Name | Type | Description |
|------|------|-------------|
| record | SObject | `SObject` |
| fieldNode | [Node](Node.md) | `Node` |

#### Return Type
**[WhereLogicComparisonResults](WhereLogicComparisonResults.md)**

,[object Object]

#### Throws
[ValidationException](../exceptions/ValidationException.md):