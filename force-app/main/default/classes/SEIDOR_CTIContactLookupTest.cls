/**********************************************************************************
Desarrollado por: Seidor
Autor: (Brayan Baquero - BB)
Proyecto: Watts
Descripción: Clase teste para calse apex SEIDOR_CTIContactLookup
---------------------------------------------------------------------------------
No. Fecha                Autor                     Descripción
------ ---------- ---------------------------------------------------------------
1.0 27-01-2026           BB                     Creación de la Clase.    
***********************************************************************************/

@IsTest
public class SEIDOR_CTIContactLookupTest {

    @TestSetup
    static void setupData() {
        Contact c1 = new Contact(
            FirstName = 'Juan',
            LastName = 'Pérez',
            MobilePhone = '+5698784111'
        );

        Contact c2 = new Contact(
            FirstName = 'Ana',
            LastName = 'Gómez',
            MobilePhone = '+5698784118'
        );

        insert new List<Contact>{ c1, c2 };
    }

    @IsTest
    static void testFindByNormalizedPhone() {
        Test.startTest();
        Id contactId = SEIDOR_CTIContactLookup.findContactIdByPhone('+5698784111');
        Test.stopTest();

        System.assertNotEquals(
            null,
            contactId,
            'Debe encontrar un contacto usando coincidencia por termina en'
        );
    }

    @IsTest
    static void testFindByExactPhone() {
        Contact c = [
            SELECT Id
            FROM Contact
            WHERE MobilePhone = '+5698784118'
            LIMIT 1
        ];

        Test.startTest();
        Id contactId = SEIDOR_CTIContactLookup.findContactIdByPhone('+5698784118');
        Test.stopTest();

        System.assertEquals(
            c.Id,
            contactId,
            'Debe encontrar el contacto por match exacto'
        );
    }

    @IsTest
    static void testPhoneNullOrBlank() {
        Test.startTest();
        Id resultNull = SEIDOR_CTIContactLookup.findContactIdByPhone(null);
        Id resultBlank = SEIDOR_CTIContactLookup.findContactIdByPhone('');
        Test.stopTest();

        System.assertEquals(null, resultNull);//NOPMD
        System.assertEquals(null, resultBlank);//NOPMD
    }

    @IsTest
    static void testPhoneWithoutDigits() {
        Test.startTest();
        Id result = SEIDOR_CTIContactLookup.findContactIdByPhone('---()');
        Test.stopTest();

        System.assertEquals(
            null,
            result,
            'Si no hay dígitos, debe retornar null'
        );
    }
}