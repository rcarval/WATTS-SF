import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import enqueueCreateItems from '@salesforce/apex/SEIDOR_CargaDeProductos.enqueueCreateItems';


const TAMANO_PREVISUALIZACION = 20;
const HEADERS_REQUERIDOS = [
    'cgcloud__Order_Item_Template__c',
    'cgcloud__Product__c',
    'cgcloud__Quantity__c'
];

const ALIAS_HEADERS = {
    // Plantilla
    templateId: 'cgcloud__Order_Item_Template__c',
    orderItemTemplate: 'cgcloud__Order_Item_Template__c',
    productTemplateExternalId: 'cgcloud__Order_Item_Template__c',
    cgcloud__Order_Item_Template__c: 'cgcloud__Order_Item_Template__c',

    // Producto 
    consumerGoodsProductCode: 'cgcloud__Product__c',
    consumer_goods_product_code: 'cgcloud__Product__c',
    cgcloud__Consumer_Goods_Product_Code__c: 'cgcloud__Product__c',
    cgcloud__Product__c: 'cgcloud__Product__c',

    // Cantidad
    quantity: 'cgcloud__Quantity__c',
    qty: 'cgcloud__Quantity__c',
    cgcloud__Quantity__c: 'cgcloud__Quantity__c'
};

export default class LwcCargaMasiva extends LightningElement {
    @api recordId; //  Id de la Orden actual 


    @track modoCarga = 'paste';
    @track contenidoPegado = '';
    @track nombreArchivo = '';
    archivosSubidos = [];

    @track columnasPrevisualizacion = [];
    @track datosPrevisualizacion = [];
    @track filasCompletas = [];
    @track cargando = false;

    get opcionesModoCarga() {
        return [
            { label: 'Pegar desde Excel', value: 'paste' },
            { label: 'Archivo CSV', value: 'file' }
        ];
    }
    get esModoPegado() { return this.modoCarga === 'paste'; }
    get esModoArchivo() { return this.modoCarga === 'file'; }
    get hayPrevisualizacion() { return Array.isArray(this.datosPrevisualizacion) && this.datosPrevisualizacion.length > 0; }
    get tamanoPrevisualizacion() { return TAMANO_PREVISUALIZACION; }
    get deshabilitarPrevisualizarArchivo() { return !(this.archivosSubidos && this.archivosSubidos.length); }

   
    handleCambioModo(e) {
        this.modoCarga = e.detail.value;
        this.limpiarTodo();
    }

    handleCambioPegado(e) {
        this.contenidoPegado = e.target.value;
    }

    handleCambioArchivo(e) {
        if (e.target.files && e.target.files.length > 0) {
            this.archivosSubidos = e.target.files;
            this.nombreArchivo = e.target.files[0].name;
        } else {
            this.archivosSubidos = [];
            this.nombreArchivo = '';
        }
    }


    previsualizarDesdePegado = () => {
        try {
            const filas = this.parsearTsvConHeader(this.contenidoPegado);
            this.setPrevisualizacion(filas);
        } catch (err) {
            this.toast('Error', err?.message || 'No se pudo previsualizar.', 'error');
        }
    };

    previsualizarDesdeArchivo = () => {
        if (!this.archivosSubidos.length) {
            this.toast('Error', 'Selecciona un archivo CSV.', 'error');
            return;
        }

        const archivo = this.archivosSubidos[0];
        const reader = new FileReader();

        reader.onload = () => {
            try {
                const filas = this.parsearCsvConHeader(reader.result);
                this.setPrevisualizacion(filas);
            } catch (err) {
                this.toast('Error', err?.message || 'No se pudo previsualizar el CSV.', 'error');
            }
        };

        reader.onerror = () => this.toast('Error', 'No se pudo leer el archivo.', 'error');
        reader.readAsText(archivo);
    };

    
    setPrevisualizacion(filas) {
        if (!filas || !filas.length) throw new Error('No se detectaron filas.');

        const headersArchivo = Object.keys(filas[0] || {});
        if (!headersArchivo.length) throw new Error('No se detectaron headers.');

        const normalizarHeader = (h) =>
            String(h || '')
                .trim()
                .replace(/^"|"$/g, ''); 

        const mapaHeaders = {};
        headersArchivo.forEach((hOriginal) => {
            const hNorm = normalizarHeader(hOriginal);
            mapaHeaders[hNorm] = ALIAS_HEADERS[hNorm] || hNorm;
        });


        const headersDestino = new Set(Object.values(mapaHeaders));
        const faltantes = HEADERS_REQUERIDOS.filter((req) => !headersDestino.has(req));
        if (faltantes.length) {
            throw new Error(`Faltan headers requeridos: ${faltantes.join(', ')}`);
        }


        this.filasCompletas = filas.map((fila) => {
            const salida = {
                cgcloud__Order_Item_Template__c: '',
                cgcloud__Product__c: '',
                cgcloud__Quantity__c: ''
            };

            Object.keys(fila).forEach((k0) => {
                const kNorm = normalizarHeader(k0);
                const destino = mapaHeaders[kNorm];
                if (HEADERS_REQUERIDOS.includes(destino)) {
                    salida[destino] = String(fila[k0] ?? '').trim();
                }
            });

            return salida;
        });


        this.columnasPrevisualizacion = HEADERS_REQUERIDOS.map((h) => ({ label: h, fieldName: h }));
        this.datosPrevisualizacion = this.filasCompletas.slice(0, TAMANO_PREVISUALIZACION).map((r, idx) => ({
            __rowKey: String(idx),
            ...r
        }));


        const ignoradas = headersArchivo
            .map(normalizarHeader)
            .filter((h) => !HEADERS_REQUERIDOS.includes(mapaHeaders[h]));
        if (ignoradas.length) {
            this.toast('Info', `Se ignoraron ${ignoradas.length} columnas extra del archivo.`, 'info');
        }
    }

    limpiarTodo = () => {
        this.contenidoPegado = '';
        this.nombreArchivo = '';
        this.archivosSubidos = [];
        this.columnasPrevisualizacion = [];
        this.datosPrevisualizacion = [];
        this.filasCompletas = [];
        this.cargando = false;

        const inputArchivo = this.template.querySelector('[data-id="inputArchivo"]');
        if (inputArchivo) {
            inputArchivo.value = null;
        }
    };

    guardar = async () => {
        if (!this.recordId) {
            this.toast('Error', 'No se detectó la Orden actual recordId.', 'error');
            return;
        }
        if (!this.filasCompletas || !this.filasCompletas.length) {
            this.toast('Error', 'Primero genera una previsualización.', 'error');
            return;
        }

        this.cargando = true;

        try {
            //   SOLO 4 campos y order se toma del recordId
            const filasParaApex = this.filasCompletas.map((fila) => {
                const idPlantillaItem = (fila.cgcloud__Order_Item_Template__c || '').trim() || null;
                const producto = (fila.cgcloud__Product__c || '').trim() || null; //  códigopoduct
                const cantidad = this.aNumero(fila.cgcloud__Quantity__c);

                return {
                    cgcloud__Order__c: this.recordId,
                    cgcloud__Order_Item_Template__c: idPlantillaItem,
                    cgcloud__Product__c: producto,
                    cgcloud__Quantity__c: cantidad
                };
            });

            const filasLimpias = JSON.parse(JSON.stringify(filasParaApex));
            const res = await enqueueCreateItems({ rows: filasLimpias });

            this.limpiarTodo();
        
            this.toast(
                'Carga en proceso',
                `Filas: ${res.totalFilas} `,
                'success'
            );
        } catch (e) {

            console.error('ERROR APEX =>', e);
            this.toast('Error', this.normalizarError(e), 'error');
        } finally {
            this.cargando = false;
        }
    };

    aNumero(val) {
        if (val === null || val === undefined || val === '') return null;
        const n = Number(String(val).replace(',', '.'));
        return Number.isFinite(n) ? n : null;
    }

    normalizarError(e) {
        if (!e) return 'Error desconocido';
        if (Array.isArray(e.body)) return e.body.map((x) => x.message).join(' | ');
        if (e.body && e.body.message) return e.body.message;
        return e.message || JSON.stringify(e);
    }

 
    parsearTsvConHeader(texto) {
        if (!texto || !texto.trim()) throw new Error('No hay contenido pegado.');

        const lineas = texto.replace(/\r\n/g, '\n').split('\n').filter((l) => l.trim() !== '');
        if (lineas.length < 2) throw new Error('Debe haber headers y al menos una fila de datos.');

        const headers = lineas[0].split('\t').map((h) => h.trim());
        const filas = [];

        for (let i = 1; i < lineas.length; i++) {
            const cols = lineas[i].split('\t');
            const obj = {};
            headers.forEach((h, idx) => {
                obj[h] = (cols[idx] ?? '').trim();
            });
            filas.push(obj);
        }
        return filas;
    }

    parsearCsvConHeader(csvText) {
        if (!csvText || !csvText.trim()) throw new Error('CSV vacío.');

        const lineas = csvText.replace(/\r\n/g, '\n').split('\n').filter((l) => l.trim() !== '');
        if (lineas.length < 2) throw new Error('Debe haber headers y al menos una fila de datos.');

        const headerLine = lineas[0];
        const commaCount = (headerLine.match(/,/g) || []).length;
        const semiCount = (headerLine.match(/;/g) || []).length;
        const delimitador = semiCount > commaCount ? ';' : ',';

        const headers = headerLine.split(delimitador).map((h) => h.trim());
        const filas = [];

        for (let i = 1; i < lineas.length; i++) {
            const cols = lineas[i].split(delimitador);
            const obj = {};
            headers.forEach((h, idx) => {
                obj[h] = (cols[idx] ?? '').trim();
            });
            filas.push(obj);
        }
        return filas;
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}