/**********************************************************************************
Desarrollado por: Seidor
Autor: (Brayan Baquero - BB)
Proyecto: Watts
Descripción: clase test de la clase apex de Controlador para la visualforce para generar el resumen del Ticket Caso y
cargar la lista dinámica de productos del objeto Producto_Centrales__c.
---------------------------------------------------------------------------------
No. Fecha                Autor                     Descripción
------ ---------- ---------------------------------------------------------------
1.0 18-02-2026           BB                     Creación de la Clase test.
1.1 06-05-2026           Seidor                 Tests para savePdfToCase().
***********************************************************************************/
@IsTest
public class SEIDOR_ResumenTicketControllerTest {

    // =========================================================
    // TEST 1: Case sin Id -> el controller debe dejar caso null
    // =========================================================
    @IsTest
    static void testController_caseIdNull() {
        Case c = new Case(
            Subject = 'Caso sin Id',
            Origin  = 'Phone',
            Status  = 'New'
        );

        ApexPages.StandardController sc = new ApexPages.StandardController(c);

        Test.startTest();
        SEIDOR_ResumenTicketController ctrl = new SEIDOR_ResumenTicketController(sc);
        Test.stopTest();

        System.assertEquals(null, ctrl.caso);
        System.assertNotEquals(null, ctrl.productosCentral);
        System.assertEquals(false, ctrl.getTieneProductosCentral());
    }


    // =========================================================
    // TEST 3: Caso REAL sin Producto_Centrales__c (SeeAllData)
    // =========================================================
    /*@IsTest(SeeAllData=true)
    static void testController_sinProductosCentral_ok() {

        // Busca un Case que NO tenga Producto_Centrales__c
        List<Case> casesSinPc = [
            SELECT Id
            FROM Case
            WHERE Id NOT IN (SELECT Case__c FROM Producto_Centrales__c WHERE Case__c != null)
            LIMIT 1
        ];

        System.assert(!casesSinPc.isEmpty(),
            'No existe ningún Case sin Producto_Centrales__c en la org. ' +
            'Crea al menos 1 Case SIN registros Producto_Centrales__c (manual) para que este test sea estable.'
        );

        ApexPages.StandardController sc = new ApexPages.StandardController(casesSinPc[0]);

        Test.startTest();
        SEIDOR_ResumenTicketController ctrl = new SEIDOR_ResumenTicketController(sc);
        Test.stopTest();

        System.assertNotEquals(null, ctrl.caso);
        System.assertEquals(false, ctrl.getTieneProductosCentral(), 'No debe marcar productos centrales');
        System.assertNotEquals(null, ctrl.productosCentral);
        System.assertEquals(0, ctrl.productosCentral.size(), 'La lista debe venir vacía');
    }
	*/

    // =========================================================
    // TEST 4: savePdfToCase - guarda anti-recursión activa.
    // =========================================================
    @IsTest
    static void testSavePdfToCase_guardaAntiRecursion() {
        Case c = new Case(Subject = 'Caso PDF', Status = 'New', Origin = 'Phone');
        insert c;

        // Bypassear la dependencia estricta de metadatos para evitar el GACK
        PageReference pr = new PageReference('/apex/SEIDOR_ResumenTicketCliente');
        pr.getParameters().put('id', c.Id);
        pr.getParameters().put('attached', 'true');
        Test.setCurrentPage(pr);

        ApexPages.StandardController sc = new ApexPages.StandardController(c);
        SEIDOR_ResumenTicketController ctrl = new SEIDOR_ResumenTicketController(sc);

        Test.startTest();
        PageReference result = ctrl.savePdfToCase();
        Test.stopTest();

        System.assertEquals(null, result, 'savePdfToCase debe retornar null');
        Integer cnt = [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :c.Id];
        System.assertEquals(0, cnt, 'No se debe adjuntar archivo en la llamada interna (attached=true)');
    }

    // =========================================================
    // TEST 5: savePdfToCase - sin Id en el Case, no hace nada.
    // =========================================================
    @IsTest
    static void testSavePdfToCase_sinIdCaso() {
        Case c = new Case(Subject = 'Sin Id', Status = 'New', Origin = 'Phone');

        PageReference pr = Page.SEIDOR_ResumenTicketCliente;
        Test.setCurrentPage(pr);

        ApexPages.StandardController sc = new ApexPages.StandardController(c);
        SEIDOR_ResumenTicketController ctrl = new SEIDOR_ResumenTicketController(sc);

        Test.startTest();
        PageReference result = ctrl.savePdfToCase();
        Test.stopTest();

        System.assertEquals(null, result);
    }

    // =========================================================
    // TEST 6: savePdfToCase - flujo feliz, adjunta el PDF al Case.
    // (Test.isRunningTest() hace que se use un Blob fake en el controller).
    // =========================================================
    @IsTest
    static void testSavePdfToCase_adjuntaPdfAlCaso() {
        Case c = new Case(Subject = 'Caso PDF OK', Status = 'New', Origin = 'Phone');
        insert c;

        PageReference pr = Page.SEIDOR_ResumenTicketCliente;
        pr.getParameters().put('id', c.Id);
        Test.setCurrentPage(pr);

        ApexPages.StandardController sc = new ApexPages.StandardController(c);
        SEIDOR_ResumenTicketController ctrl = new SEIDOR_ResumenTicketController(sc);

        Test.startTest();
        PageReference result = ctrl.savePdfToCase();
        Test.stopTest();

        System.assertEquals(null, result, 'savePdfToCase debe retornar null para que la página continúe renderizando');

        List<ContentDocumentLink> links = [
            SELECT Id, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :c.Id
        ];
        System.assertEquals(1, links.size(), 'Debe quedar exactamente un archivo adjunto al Case');

        ContentVersion cv = [
            SELECT Title, PathOnClient
            FROM ContentVersion
            WHERE ContentDocumentId = :links[0].ContentDocumentId
            LIMIT 1
        ];
        // ApexPages.currentPage().getUrl() devuelve la ruta en minúsculas,
        // así que comparamos case-insensitive.
        System.assert(cv.Title.toLowerCase().startsWith('seidor_resumenticketcliente'),
            'El nombre del archivo debe partir del nombre de la página: ' + cv.Title);
        System.assert(cv.PathOnClient.endsWith('.pdf'), 'La extensión debe ser .pdf');
    }
}