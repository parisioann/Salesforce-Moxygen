# Salesforce Moxygen

Salesforce Moxygen is an intuitive Salesforce mocking framework for Apex unit testing.

Moxygen is unique from other unit testing frameworks in that it includes a functional in-memory mock database that can handle most SOQL queries, parse them, and return the correct results. This means, in most cases, it is not required to specify what's returned from queries or to stub the data access object.

The ORM object encapsulates both DML and query logic by creating non-static wrappers around
their respective static Database methods.

Using this, we can mock the Selector and DML classes using interface trickery.

## Example

Lets say you have an AccountService class like so:

```
public class AccountService {
	
    @TestVisible
    private IORM db = new ORM();

    public void updateAcctName(Id accountId) {

        Map<String, Object> binds = new Map<String, Object> {
            'acctId' => accountId
        };

        // one-to-one wrapper around Database.queryWithBinds
        List<Account> acctList = db.getSelector().queryWithBinds(
            'SELECT Name FROM Account WHERE Id = :acctId',
            binds,
            AccessLevel.USER_MODE
        );

        for(Account acct : acctList) {
            acct.Name = 'WOOOO!!!!';
        }

        // one-to-one wrapper around Database.update
        db.getDML().doUpdate(acctList, true);
    }
}
```

To test this, you can create an account with an @TestSetup class... orr....

```
@IsTest
public class AccountServiceTest {

    @IsTest
    private static void testUpdateAcctName() {
        MockORM db = new MockORM();
        MockDML dml = db.getMockDML();

        Account newAcct = new Account(
            Name = 'Lame'
        );

        dml.doMockInsert(newAcct);
        
        AccountService service = new AccountService();
        service.db = db;

        // we used doMockInsert, so no DML is registered
        Assert.isFalse(
            db.didAnyDML(),
            'Expected no DML statement to register'
        );

        Test.startTest();
            service.updateAcctName(newAcct.Id);
        Test.stopTest();
        
        Account updatedAcct = (Account) db.selectRecordById(newAcct.Id);

        // Did we actually update the record?
        Assert.areEqual(
            'WOOOO!!!!',
            updatedAcct.Name,
            'Expected account name to be updated'
        );

        // check for any DML
        Assert.isTrue(
            db.didAnyDML(),
            'Expected DML to fire'
        );


        // check for a specific DML operation
        Assert.isTrue(
            db.didDML(Types.DML.UPDATED),
            'Expected data to be updated'
        );

        // did we call a query?
        Assert.isTrue(
            db.calledAnyQuery(),
            'Expected some query to be called'
        );

        // check that our query was called
        Assert.isTrue(
            db.calledQuery('SELECT Name FROM Account WHERE Id = :acctId'),
            'Expected query to be called'
        );
    }
}
```

# Mock SOQL Database

Under the hood, a mock SOQL parser is used to handle queries. It can be instantiated on its own as shown below.

## Example
```
Account a = new Account(Name = 'Test1', NumberOfEmployees = 5);
Account b = new Account(Name = 'Test1', NumberOfEmployees = 10);
Account c = new Account(Name = 'Test2', NumberOfEmployees = 15);
Account d = new Account(Name = 'Test2', NumberOfEmployees = 20);
MockDatabase mockDb = new MockDatabase();
List<Account> acctList = new List<Account>{a, b, c, d};
mockDb.doInsert(acctList);

Test.startTest();
    List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT Name, SUM(NumberOfEmployees) FROM Account GROUP BY Name ORDER BY Name ASC');
Test.stopTest();

Assert.areEqual('Test1', queriedAccts[0].get('Name'), 'Incorrect order');
Assert.areEqual('Test2', queriedAccts[1].get('Name'), 'Incorrect order');
```


A SOQL query will have the following format.

```
SELECT fieldList [subquery][...]
[TYPEOF typeOfField whenExpression[...] elseExpression END][...]
FROM objectType[,...] 
    [USING SCOPE filterScope]
[WHERE conditionExpression]
[WITH [DATA CATEGORY] filteringExpression]
[GROUP BY {fieldGroupByList|ROLLUP (fieldSubtotalGroupByList)|CUBE (fieldSubtotalGroupByList)} 
    [HAVING havingConditionExpression] ] 
[ORDER BY fieldOrderByList {ASC|DESC} [NULLS {FIRST|LAST}] ]
[LIMIT numberOfRowsToReturn]
[OFFSET numberOfRowsToSkip]
[{FOR VIEW  | FOR REFERENCE} ]
[UPDATE {TRACKING|VIEWSTAT} ]
[FOR UPDATE]
```

# Levels of Support
There are four categories of support for a SOQL query done via the mock SOQL database.
* Fully Supported
* Partially Supported
* Ignored
  * It won't throw an exception when parsed, but won't be applied by the mock database
* Not Supported
  * Throws a QueryException when read by the parser

# Supported Clauses
| Clause      | Level of Support    | Notes |
|-------------|---------------------|-------|
| SELECT      | Partially Supported | FORMAT(), convertCurrency(), convertTimezone(), date functions, GROUPING(), and toLabel() are not supported |
| TYPEOF      | Fully Supported     ||
| FROM        | Fully Supported     ||
| USING SCOPE | Ignored             ||
| WHERE       | Fully Supported ||
| WITH        | Not Supported       ||
| GROUP BY    | Partially Supported | GROUP BY ROLLUP and GROUP BY CUBE are not supported |
| HAVING | Fully Supported ||
| ORDER BY | Fully Supported ||
| LIMIT | Fully Supported ||
| OFFSET | Fully Supported ||
| FOR VIEW\|REFERENCE | Ignored ||
| UPDATE TRACKING\|VIEWSTAT | Not Supported ||
| FOR UPDATE | Ignored ||

## Classes

### IORM

The IORM interface defines two methods that can be expected to exist on both the MockORM and ORM classes,

- ISelector getSelector()
- IDML getDML()

### ISelector

The ISelector interface defines three methods,

- List\<SObject\> query(String queryString)
- List\<SObject\> query(String queryString, System.AccessLevel accessLevel)
- List\<SObject\> queryWithBinds(String queryString, Map\<String, Object\> bindMap, System.AccessLevel accessLevel)

- List\<Aggregate\> queryAggregate(String queryString);
- List\<Aggregate\> queryAggregate(String queryString, System.AccessLevel accessLevel);
- List\<Aggregate\> queryAggregateWithBinds(String queryString, Map\<String, Object\> bindMap, System.AccessLevel accessLevel);

### IDML

The IDML interface defines the following methods, reflecting their equivalent static Database methods.

- Database.DeleteResult doDelete(SObject recordToDelete, Boolean allOrNone)
- List\<Database.DeleteResult\> doDelete(List\<SObject\> recordsToDelete, Boolean allOrNone)
- Database.DeleteResult doDelete(Id recordID, Boolean allOrNone)
- List\<Database.DeleteResult\> doDelete(List\<Id\> recordIDs, Boolean allOrNone)

- Database.SaveResult doInsert(SObject recordToInsert, Boolean allOrNone)
- List\<Database.SaveResult\> doInsert(List\<SObject\> recordsToInsert, Boolean allOrNone)
- Database.SaveResult doInsert(SObject recordToInsert, Boolean allOrNone, System.AccessLevel accessLevel)
- List\<Database.SaveResult\> doInsert(List\<SObject\> recordsToInsert, Boolean allOrNone, System.AccessLevel accessLevel)

- Database.SaveResult doUpdate(SObject recordToUpdate, Boolean allOrNone)
- List\<Database.SaveResult\> doUpdate(List\<SObject\> recordsToUpdate, Boolean allOrNone)
- Database.SaveResult doUpdate(SObject recordToUpdate, Boolean allOrNone, System.AccessLevel accessLevel)
- List\<Database.SaveResult\> doUpdate(List\<SObject\> recordsToUpdate, Boolean allOrNone, System.AccessLevel accessLevel)

- Database.UpsertResult doUpsert(SObject recordToUpsert, SObjectField externalIdField, Boolean allOrNone)
- List\<Database.UpsertResult\> doUpsert(List\<SObject\> recordsToUpsert, SObjectField externalIdField, Boolean allOrNone)
- Database.UpsertResult doUpsert(SObject recordToUpsert, SObjectField externalIdField, Boolean allOrNone, System.AccessLevel accessLevel)
- List\<Database.UpsertResult\> doUpsert(List\<SObject\> recordsToUpsert, SObjectField externalIdField, Boolean allOrNone, System.AccessLevel accessLevel)

- Database.UndeleteResult doUndelete(sObject recordToUndelete, Boolean allOrNone)
- List\<Database.UndeleteResult\> doUndelete(List\<SObject\> recordsToUndelete, Boolean allOrNone)
- Database.UndeleteResult doUndelete(Id recordID, Boolean allOrNone)
- List\<Database.UndeleteResult\> doUndelete(List\<Id\> recordIDs, Boolean allOrNone)
- Database.UndeleteResult doUndelete(SObject recordToUndelete, Boolean allOrNone, System.AccessLevel accessLevel)

### ORM

The ORM class is the implementation of the IORM that that is meant for regular use.

#### ISelector getSelector()

Returns a Selector object

#### getDML()

Returns a DML object

### Selector

The Selector class implements the ISelector methods as wrappers around their Database methods.
ex.

```
public List<SObject> query(String queryString) {
    return Database.query(queryString);
}
```

### DML

The DML class class is a wrapper around the DML-related Database methods. They behave the same as
the Selector methods. The only thing to note is that DML operations are reserved words in Apex, so
all methods are prefixed with "do",

i.e.

- doUpdate
- doInsert
- doUpsert
- etc.

### MockORM

The MockORM object is used for mocking database interactions. It keeps a mock database tracked
internally for records that have been fake-inserted.

#### ISelector getSelector()

Returns a MockSelector object

#### IDML getDML()

Returns a MockDML object

These need to be cast to MockDML and MockSelector get the full use out of them.
For testing, the following methods are also defined,

### MockSelector getMockSelector()

Returns the MockSelector object, without the need to type-cast it.

### MockDML getMockDML()

Returns the MockDML object, without the need to type-cast it.

#### public Boolean didAnyDML()

Returns where any DML operation was performed by the mock database.

#### public Boolean didDML(Types.DML type)

Returns whether a specific DML operation was performed.
The options for type are:

Types.DML.INSERTED
Types.DML.UPSERTED
Types.DML.UPDATED
Types.DML.DELETED
Types.DML.UNDELETED

#### public Boolean calledAnyQuery()

Returns whether any query was called.

#### public Boolean calledQuery(String queryString)

Returns whether a specific query was called.

#### public void reset()

Resets the tracking on queries and DML operations, does NOT reset the mock database records.

#### public void resetDML()

Resets the tracking on DML operations

#### public void resetSelector()

Resets the tracking on SOQL queries

#### public void registerQuery(String queryString, List\<SObject\> records)

Register a query so that when it is called, it returns a specific set of SObjects.
Because the SObjects are passed in a list, edits to these SObjects will be reflected
in the mock database (i.e. pointer logic).

If a query is registered, the mock soql database will not be used.

#### public void registerFailedQuery(String queryString)

Register a query such that when it is called, an exception is thrown.
This throws a generic QueryException.

#### public void registerAggregateQuery(String queryString, List\<Aggregate\> records)

Register an aggregate query to return a list of Aggregate objects when its called.

If a query is registered, the mock soql database will not be used.

#### public void registerFailedAggregateQuery(String queryString)

Register a failed aggregate query. Will throw a QueryException when called (via the queryAggregate methods).

#### public void registerCountQuery(String queryString, Integer count)

Register a count query (i.e. a call to queryCount).

If a query is registered, the mock soql database will not be used.

#### public void registerFailedCountQuery(String queryString)

Register a failed count query. Throws a QueryException.

#### public Boolean isDeleted(Id recordId)

Returns whether a record has been deleted, given the fake ID
that was created for it when it was inserted

#### public SObject selectRecordById(Id recordId)

Retrieve a record from the mock database, by Id.

NOTE: This will grab deleted records.

### MockSelector

This is a mock version of the selector.

#### public List\<SObject\> query(String queryString)

- If this query was not registered, queries the database via the mock soql database
- Returns a list of SObjects if this query was registered via "registerQuery"
- Throws an exception if this query was registered via "registerFailedQuery"

#### public List\<SObject\> query(String queryString, System.AccessLevel accessLevel)

Same behavior as query, accessLevel is ignored.

#### public List\<SObject\> queryWithBinds(String queryString, Map\<String, Object\> bindMap, System.AccessLevel accessLevel)

- If a query is registered, Same behavior as query, bindMap and accessLevel are ignored.
- If a query is not registered, performs a query with binds call through the mock soql database.

#### public List\<Aggregate\> queryAggregate(String queryString)

- If this query was not registered, queries the mock soql database
- Returns a list of Aggregates if this query was registered via "registerAggregateQuery"
- Throws an exception if this query was registered via "registerFailedAggregateQuery"

#### public List\<Aggregate\> queryAggregate(String queryString, System.AccessLevel accessLevel)

Same behavior as queryAggregate, accessLevel is ignored

#### List\<Aggregate\> queryAggregateWithBinds(String queryString, Map\<String, Object\> bindMap, System.AccessLevel accessLevel);

- If the query was not registered, performs a query with binds on the mock soql database
- Otherwise, same behavior as queryAggregate, bindMap and accessLevel are ignored.

### MockDML

The MockDML methods update the system fields on the SOBject and persist them to a mock database
under the hood.

Unique methods for this class, that aren't covered by IDML or are hoisted to MockORM are,

#### void doMockInsert(List\<SObject\> recordsToInsert)

Inserts a list of records into the mock database without it registering as a DML statement,
used for setting mock data. Populates system fields.

#### void doMockInsert(SObject recordToInsert)

Inserts a record into the mock database. Populates system fields.

### Aggregate

This object is a wrapper around AggregateResult. The reason for its existence is that
AggregateResult objects cannot be mocked. It takes the AggregateResult record, and perserves
it as a read-only Map\<String, Object\>.

#### public Object get(String field)

Returns the value on the aggregate keyed by "field"

### RelationshipBuilder

Utility for relating child and parent records for mock queries.

This class has two methods

#### public ChildRelationshipBuilder relateChildren()

Returns a ChildRelationshipBuilder to relate one record (the parent)
to many children.

This class has five methods, four of which are setters and then there is the
build method which returns the connected SObject.

- public ChildRelationshipBuilder setParent(SObject parent)
- public ChildRelationshipBuilder setChildren(List\<SObject\> children)
- public ChildRelationshipBuilder setRelationshipName(String relationshipName)
- public ChildRelationshipBuilder setRelationshipField(String relationshipField)
- public SObject build()

Note: calling `build()` will throw an illegal argument exception if any of the
fields are not set.

#### public ParentRelationshipBuilder relateParent()

Returns a ParentRelationshipBuilder to relate one record (the child)
to the parent.

This class has five methods, four of which are setters, and then there is the
build method which returns the connected SObject.

- public ParentRelationshipBuilder setChild(SObject child)
- public ParentRelationshipBuilder setParent(SObject parent)
- public ParentRelationshipBuilder setRelationshipName(String relationshipName)
- public ParentRelationshipBuilder setRelationshipField(String relationshipField)
- public SObject build()

Note: calling `build()` will throw an illegal argument exception if any of the
fields are not set.

ex.

```
// [SELECT Account.Name FROM Opportunity]
Opportunity oppWithAcct = (Opportunity) new RelationshipBuilder()
    .relateParent()
        .setChild(opp)
        .setParent(acct)
        .setRelationshipField('AccountId')
        .setRelationshipName('Account')
        .build();

// [SELECT (SELECT Name FROM Opportunties) FROM Account]
Account acctWithOpps = (Account) new RelationshipBuilder()
    .relateChildren()
        .setParent(acct)
        .setChildren(oppList)
        .setRelationshipField('AccountId')
        .setRelationshipName('Opportunities')
        .build();
```

### Common

Handles common operations handled throughout the codebase. Contains useful methods for mocking.

#### public static void nullCheck(Map\<String, Object\> args)

Takes a `Map<String, Object>` and checks if any of the values are null. Used to check that the arguments are methods aren't null.

#### public static SObject putReadOnlyField(SObject record, String fieldName, Object value)

Given a record, a field name, and a value, sets that value on a record.

#### public static SObject putReadOnlyFields(SObject record, Map\<String, Object\> fieldValuePairs)

Given a record and a `Map<String, Object>`, set all values in the map on the record.

#### public static Map\<String, Object\> mapFromRecord(SObject record)

Returns an editable `Map<String, Object>` from a record.

#### public static SObject recordFromMap(Map\<String, Object\> recordMap, String sObjectType)

Returns a new record from a `Map<String, Object>` of the specified SObject type.