/**********************************************************************************
Desarrollado por: Seidor
Proyecto: Watts
Descripción: Servicio reutilizable para adjuntar archivos (Blob) a un registro
             de Salesforce a través de la lista relacionada estándar de "Archivos"
             (ContentVersion + ContentDocumentLink).
---------------------------------------------------------------------------------
No.   Fecha           Autor                          Descripción
----- --------------- ------------------------------ ----------------------------
1.0   06-05-2026      Seidor                         Creación de la clase.
***********************************************************************************/
public with sharing class SEIDOR_PdfFileService {

    public class SEIDOR_PdfFileServiceException extends Exception {}

    private static final String DEFAULT_FILE_NAME = 'Documento';
    private static final String EXTENSION_PDF     = '.pdf';

    /**
     * Adjunta un PDF (Blob) al registro indicado mediante Files estándar.
     *
     * @param parentId      Id del registro al que se vinculará el archivo (p.ej. el Case).
     * @param pdfBody       Contenido binario del PDF.
     * @param baseFileName  Nombre base (sin extensión). Si viene vacío se usa "Documento".
     * @return              Id del ContentDocument creado.
     */
    public static Id attachPdfToRecord(Id parentId, Blob pdfBody, String baseFileName) {
        if (parentId == null) {
            throw new SEIDOR_PdfFileServiceException('parentId es obligatorio.');
        }
        if (pdfBody == null) {
            throw new SEIDOR_PdfFileServiceException('pdfBody es obligatorio.');
        }

        String safeName = String.isBlank(baseFileName) ? DEFAULT_FILE_NAME : baseFileName.trim();

        ContentVersion cv = new ContentVersion(
            Title          = safeName,
            PathOnClient   = safeName + EXTENSION_PDF,
            VersionData    = pdfBody,
            IsMajorVersion = true
        );
        insert cv;

        Id contentDocumentId = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ].ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId    = parentId,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );
        insert cdl;

        return contentDocumentId;
    }
}