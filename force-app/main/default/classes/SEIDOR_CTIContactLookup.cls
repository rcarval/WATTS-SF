/**********************************************************************************
Desarrollado por: Seidor
Autor: (Brayan Baquero - BB)
Proyecto: Watts
Descripción: Clase clase consulta de contacto con el phone-
---------------------------------------------------------------------------------
No. Fecha                Autor                     Descripción
------ ---------- ---------------------------------------------------------------
1.0 26-01-2026           BB                     Creación de la Clase.    
***********************************************************************************/

public with sharing class SEIDOR_CTIContactLookup {
     @AuraEnabled(cacheable=true)
    public static Id findContactIdByPhone(String phoneRaw) {
        if (String.isBlank(phoneRaw)) {
            return null;
        }

        String digits = phoneRaw.replaceAll('[^0-9]', '');
        if (String.isBlank(digits)) {
            return null;
        }


        String likeEnds = '%' + digits;

        String exactRaw = phoneRaw.trim();

        if (!Schema.sObjectType.Contact.isAccessible()) {
    return null;
}

        List<Contact> cs = [ 
            SELECT Id
            FROM Contact
            WHERE MobilePhone LIKE :likeEnds
                OR MobilePhone = :exactRaw
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];

        return cs.isEmpty() ? null : cs[0].Id;

    }
}