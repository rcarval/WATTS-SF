/**********************************************************************************
Desarrollado por: Seidor
Proyecto: Watts
Descripción: Pruebas unitarias para SEIDOR_PdfFileService.
---------------------------------------------------------------------------------
No.   Fecha           Autor                          Descripción
----- --------------- ------------------------------ ----------------------------
1.0   06-05-2026      Seidor                         Creación de la clase test.
***********************************************************************************/
@IsTest
public class SEIDOR_PdfFileServiceTest {

    @IsTest
    static void attachPdfToRecord_creaArchivoYVinculo() {
        Case c = new Case(Subject = 'Caso de prueba', Status = 'New', Origin = 'Phone');
        insert c;

        Blob body = Blob.valueOf('CONTENIDO_PDF_DE_PRUEBA');

        Test.startTest();
        Id docId = SEIDOR_PdfFileService.attachPdfToRecord(c.Id, body, 'MiResumen');
        Test.stopTest();

        System.assertNotEquals(null, docId, 'Debe retornar el Id del ContentDocument creado');

        ContentDocumentLink link = [
            SELECT Id, ContentDocumentId, ShareType, Visibility, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :c.Id
            LIMIT 1
        ];
        System.assertEquals(docId, link.ContentDocumentId);
        System.assertEquals('V', link.ShareType);
        System.assertEquals('AllUsers', link.Visibility);

        ContentVersion cv = [
            SELECT Title, PathOnClient, IsMajorVersion
            FROM ContentVersion
            WHERE ContentDocumentId = :docId
            LIMIT 1
        ];
        System.assertEquals('MiResumen', cv.Title);
        System.assertEquals('MiResumen.pdf', cv.PathOnClient);
        System.assertEquals(true, cv.IsMajorVersion);
    }

    @IsTest
    static void attachPdfToRecord_nombreVacioUsaDefault() {
        Case c = new Case(Subject = 'Caso de prueba', Status = 'New', Origin = 'Phone');
        insert c;

        Blob body = Blob.valueOf('CONTENIDO_PDF');

        Test.startTest();
        Id docId = SEIDOR_PdfFileService.attachPdfToRecord(c.Id, body, '   ');
        Test.stopTest();

        ContentVersion cv = [
            SELECT Title, PathOnClient
            FROM ContentVersion
            WHERE ContentDocumentId = :docId
            LIMIT 1
        ];
        System.assertEquals('Documento', cv.Title);
        System.assertEquals('Documento.pdf', cv.PathOnClient);
    }

    @IsTest
    static void attachPdfToRecord_parentIdNuloLanzaExcepcion() {
        Boolean lanzo = false;
        try {
            SEIDOR_PdfFileService.attachPdfToRecord(null, Blob.valueOf('x'), 'algo');
        } catch (SEIDOR_PdfFileService.SEIDOR_PdfFileServiceException e) {
            lanzo = true;
        }
        System.assertEquals(true, lanzo, 'Se esperaba SEIDOR_PdfFileServiceException por parentId nulo');
    }

    @IsTest
    static void attachPdfToRecord_bodyNuloLanzaExcepcion() {
        Case c = new Case(Subject = 'Caso de prueba', Status = 'New', Origin = 'Phone');
        insert c;

        Boolean lanzo = false;
        try {
            SEIDOR_PdfFileService.attachPdfToRecord(c.Id, null, 'algo');
        } catch (SEIDOR_PdfFileService.SEIDOR_PdfFileServiceException e) {
            lanzo = true;
        }
        System.assertEquals(true, lanzo, 'Se esperaba SEIDOR_PdfFileServiceException por body nulo');
    }
}