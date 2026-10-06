import { LightningElement, api, wire } from 'lwc';
import { subscribe, unsubscribe, onError, setDebugFlag } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import USER_EMAIL_FIELD from '@salesforce/schema/User.Email';

import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import findContactIdByPhone from '@salesforce/apex/SEIDOR_CTIContactLookup.findContactIdByPhone';

export default class Lwcpoc extends NavigationMixin(LightningElement) {
    // Canal del Platform Event
    channelName = '/event/ctievent__e';

    // Campos del Platform Event
    correoAgenteField = 'Correo_Agente__c';
    customerPhoneField = 'Customer_Phone__c';
    lastPhone = '';

    @api highlightUtilityOnEvent = false;
    @api filterByAgentEmail = false;
    @api openUtilityOnEvent = false;
    @api showToastOnEvent = false;
    @api maxMessages = 20;

    // Usuario logueado
    userEmail = null;
    userEmailLoaded = false;

    @wire(getRecord, { recordId: USER_ID, fields: [USER_EMAIL_FIELD] })
    wiredUser({ data }) {
        this.userEmailLoaded = true;
        this.userEmail = data
            ? (data.fields.Email.value || '').trim().toLowerCase()
            : null;
    }

    // Banner fijo
    activeNotificationText = '';
    activeNotificationTimestamp = '';
    activeLinkUrl = '';
    activeLinkLabel = '';

    get hasActiveNotification() {
        return !!this.activeNotificationText;
    }

    // Historial
    messages = [];

    get hasMessages() {
        return this.messages.length > 0;
    }

    get isClearDisabled() {
        return !this.hasMessages && !this.hasActiveNotification;
    }

    subscription = null;

    // ===== Keep Alive + Reconexión =====
    keepAliveTimer = null;
    reconnectTimer = null;
    reconnectDelayMs = 2000;
    reconnectDelayMaxMs = 60000;

    // 9 minutos suele ser seguro para evitar idle timeout sin “machacar”
    keepAliveMs = 9 * 60 * 1000;

    connectedCallback() {
        setDebugFlag(false);

        // Silencioso: si hay error del canal/handshake/sesión, reintenta
        onError((err) => {
            if (this.isAuthOrChannelError(err)) {
                this.scheduleReconnect();
            } else {
                this.scheduleReconnect();
            }
        });

        this.startKeepAlive();
        void this.subscribeToChannel();
    }

    disconnectedCallback() {
        this.stopKeepAlive();
        this.clearReconnect();
        void this.unsubscribeFromChannel();
    }

    // ===== Keep Alive (NO recarga UI) =====
    startKeepAlive() {
        this.stopKeepAlive();

        this.keepAliveTimer = window.setInterval(() => {
            // Si la pestaña no está visible, no hace falta insistir
            if (document.visibilityState !== 'visible') return;

            void this.pingSession();
        }, this.keepAliveMs);
    }

    stopKeepAlive() {
        if (this.keepAliveTimer) {
            window.clearInterval(this.keepAliveTimer);
            this.keepAliveTimer = null;
        }
    }

    async pingSession() {
        // Ping liviano al mismo dominio.
        // Si la sesión expiró, normalmente responderá 401/403 y programamos reconexión.
        try {
            const res = await fetch('/services/data/v60.0/', {
                method: 'GET',
                headers: { Accept: 'application/json' },
                cache: 'no-store'
            });

            if (res.status === 401 || res.status === 403) {
                this.scheduleReconnect();
            }
        } catch {
            // Silencioso: si falla el ping, intentamos reconectar
            this.scheduleReconnect();
        }
    }

    // ===== Reconexión EMP API =====
    clearReconnect() {
        if (this.reconnectTimer) {
            window.clearTimeout(this.reconnectTimer);
            this.reconnectTimer = null;
        }
    }

    scheduleReconnect() {
        if (this.reconnectTimer) return;

        this.reconnectTimer = window.setTimeout(async () => {
            this.reconnectTimer = null;

            await this.unsubscribeFromChannel();
            await this.subscribeToChannel();
        }, this.reconnectDelayMs);

        this.reconnectDelayMs = Math.min(this.reconnectDelayMs * 2, this.reconnectDelayMaxMs);
    }

    resetReconnectBackoff() {
        this.reconnectDelayMs = 2000;
    }

    isAuthOrChannelError(err) {
        try {
            const s = typeof err === 'string' ? err : JSON.stringify(err || {});
            const lower = s.toLowerCase();
            return (
                s.includes('401') ||
                s.includes('403') ||
                lower.includes('unauthorized') ||
                lower.includes('forbidden') ||
                lower.includes('invalid session') ||
                lower.includes('handshake') ||
                lower.includes('cometd')
            );
        } catch {
            return false;
        }
    }

    // ===== EMP API =====
    async subscribeToChannel() {
        if (this.subscription) return;

        try {
            this.subscription = await subscribe(this.channelName, -1, async (response) => {
                // Si recibimos eventos, la conexión está viva -> reseteamos backoff
                this.resetReconnectBackoff();

                const payload = response?.data?.payload || {};
                const correo = (payload[this.correoAgenteField] || '').trim();
                const phone = (payload[this.customerPhoneField] || '').trim();
                const timestamp = new Date().toLocaleString();
                this.lastPhone = phone;

                // Filtro por email
                if (this.filterByAgentEmail) {
                    if (!this.userEmailLoaded || !this.userEmail) return;

                    const correoEvento = (correo || '').toLowerCase();
                    if (!correoEvento || correoEvento !== this.userEmail) return;
                }

                const safeCorreo = correo || '(sin agente)';
                const safePhone = phone || '(sin teléfono)';

                this.activeNotificationText = `Teléfono: ${safePhone} | Agente: ${safeCorreo}`;
                this.activeNotificationTimestamp = timestamp;

                let foundContactId = null;
                let foundContactUrl = null;
                let newContactUrl = null;

                try {
                    foundContactId = await findContactIdByPhone({ phoneRaw: phone });

                    if (foundContactId) {
                        foundContactUrl = await this.getContactViewUrl(foundContactId);
                        this.activeLinkUrl = foundContactUrl;
                        this.activeLinkLabel = 'Ver contacto';
                    } else {
                        newContactUrl = await this.getNewContactUrl(phone);
                        this.activeLinkUrl = newContactUrl;
                        this.activeLinkLabel = 'Crear contacto';
                    }
                } catch {
                    // Silencioso
                }

                const msg = {
                    id: Date.now() + Math.random(),
                    customerPhone: safePhone,
                    correoAgente: safeCorreo,
                    timestamp,
                    contactId: foundContactId,
                    contactUrl: foundContactUrl || newContactUrl,
                    contactLinkLabel: foundContactId ? 'Ver contacto' : 'Crear contacto'
                };

                const max = this.toPositiveInt(this.maxMessages, 20);
                this.messages = [msg, ...this.messages].slice(0, max);

                // Toast opcional SOLO si está habilitado
                if (this.showToastOnEvent) {
                    const toastUrl = foundContactUrl || newContactUrl;
                    const toastLabel = foundContactId ? 'Ver contacto' : 'Crear contacto';

                    const toastConfig = {
                        title: 'CTI - Evento recibido',
                        variant: foundContactId ? 'success' : 'warning',
                        mode: 'sticky'
                    };

                    if (toastUrl) {
                        toastConfig.message = '{0} | ' + this.activeNotificationText;
                        toastConfig.messageData = [{ url: toastUrl, label: toastLabel }];
                    } else {
                        toastConfig.message = this.activeNotificationText;
                    }

                    this.dispatchEvent(new ShowToastEvent(toastConfig));
                }
            });
        } catch {
            // Si falla subscribe (incluye sesión expirada), reintentamos sin ruido
            this.scheduleReconnect();
        }
    }

    async unsubscribeFromChannel() {
        if (!this.subscription) return;
        try {
            await unsubscribe(this.subscription);
        } catch {
            // Silencioso
        } finally {
            this.subscription = null;
        }
    }

    // ===== UI =====
    handleDismissNotification() {
        this.activeNotificationText = '';
        this.activeNotificationTimestamp = '';
        this.activeLinkUrl = '';
        this.activeLinkLabel = '';
    }

    handleClear() {
        this.messages = [];
        this.activeNotificationText = '';
        this.activeNotificationTimestamp = '';
        this.activeLinkUrl = '';
        this.activeLinkLabel = '';
    }

    // ===== Navigation =====
    async getNewContactUrl(phone) {
        const defaultFieldValues = encodeDefaultFieldValues({ Phone: phone });

        return this[NavigationMixin.GenerateUrl]({
            type: 'standard__objectPage',
            attributes: { objectApiName: 'Contact', actionName: 'new' },
            state: { defaultFieldValues }
        });
    }

    async getContactViewUrl(contactId) {
        return this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: { recordId: contactId, objectApiName: 'Contact', actionName: 'view' }
        });
    }

    toPositiveInt(value, fallback) {
        const n = Number(value);
        if (!Number.isFinite(n)) return fallback;
        const i = Math.floor(n);
        return i > 0 ? i : fallback;
    }
}