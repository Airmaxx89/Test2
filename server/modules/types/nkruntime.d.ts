// Minimale, selbst gepflegte Typdeklaration der Nakama-JS-Runtime (nkruntime).
//
// WARUM VENDORED: Die offiziellen Typen liegen im Repo heroiclabs/nakama-common
// (im offiziellen TS-Template als GitHub-Tarball-Dependency eingebunden), das in
// abgeschotteten Build-Umgebungen nicht immer erreichbar ist. Diese Datei deklariert
// bewusst NUR die von unseren Modulen genutzte API-Oberfläche — jede Erweiterung
// unserer Module ergänzt hier die entsprechenden Signaturen anhand der offiziellen
// Referenz: https://heroiclabs.com/docs/nakama/server-framework/typescript-runtime/
//
// Läuft ein Modul gegen eine Signatur, die hier falsch deklariert ist, fällt das im
// Integrationstest gegen den lokalen Docker-Stack auf (Milestone-3-Abnahme).

declare namespace nkruntime {
    interface Context {
        env: { [key: string]: string };
        executionMode: string;
        userId?: string;
        username?: string;
        matchId?: string;
        matchNode?: string;
        matchLabel?: string;
        matchTickRate?: number;
    }

    interface Logger {
        debug(format: string, ...args: any[]): void;
        info(format: string, ...args: any[]): void;
        warn(format: string, ...args: any[]): void;
        error(format: string, ...args: any[]): void;
    }

    interface Presence {
        userId: string;
        sessionId: string;
        username: string;
        node: string;
    }

    interface MatchMessage {
        sender: Presence;
        opCode: number;
        data: ArrayBuffer;
        reliable: boolean;
        receiveTimeMs: number;
    }

    interface MatchDispatcher {
        broadcastMessage(
            opCode: number,
            data?: ArrayBuffer | string | null,
            presences?: Presence[] | null,
            sender?: Presence | null,
            reliable?: boolean
        ): void;
        matchKick(presences: Presence[]): void;
        matchLabelUpdate(label: string): void;
    }

    interface MatchState {
        [key: string]: any;
    }

    interface MatchListEntry {
        matchId: string;
        authoritative: boolean;
        label?: string;
        size: number;
    }

    interface Nakama {
        binaryToString(data: ArrayBuffer): string;
        stringToBinary(str: string): ArrayBuffer;
        matchCreate(module: string, params?: { [key: string]: any }): string;
        matchList(
            limit: number,
            authoritative?: boolean | null,
            label?: string | null,
            minSize?: number | null,
            maxSize?: number | null,
            query?: string | null
        ): MatchListEntry[];
    }

    type RpcFunction = (
        ctx: Context,
        logger: Logger,
        nk: Nakama,
        payload: string
    ) => string | void;

    interface MatchHandler<State extends MatchState = MatchState> {
        matchInit: (
            ctx: Context,
            logger: Logger,
            nk: Nakama,
            params: { [key: string]: string }
        ) => { state: State; tickRate: number; label: string };

        matchJoinAttempt: (
            ctx: Context,
            logger: Logger,
            nk: Nakama,
            dispatcher: MatchDispatcher,
            tick: number,
            state: State,
            presence: Presence,
            metadata: { [key: string]: any }
        ) => { state: State; accept: boolean; rejectMessage?: string } | null;

        matchJoin: (
            ctx: Context,
            logger: Logger,
            nk: Nakama,
            dispatcher: MatchDispatcher,
            tick: number,
            state: State,
            presences: Presence[]
        ) => { state: State } | null;

        matchLeave: (
            ctx: Context,
            logger: Logger,
            nk: Nakama,
            dispatcher: MatchDispatcher,
            tick: number,
            state: State,
            presences: Presence[]
        ) => { state: State } | null;

        matchLoop: (
            ctx: Context,
            logger: Logger,
            nk: Nakama,
            dispatcher: MatchDispatcher,
            tick: number,
            state: State,
            messages: MatchMessage[]
        ) => { state: State } | null;

        matchSignal: (
            ctx: Context,
            logger: Logger,
            nk: Nakama,
            dispatcher: MatchDispatcher,
            tick: number,
            state: State,
            data: string
        ) => { state: State; data?: string } | null;

        matchTerminate: (
            ctx: Context,
            logger: Logger,
            nk: Nakama,
            dispatcher: MatchDispatcher,
            tick: number,
            state: State,
            graceSeconds: number
        ) => { state: State } | null;
    }

    interface Initializer {
        registerMatch<State extends MatchState>(
            name: string,
            functions: MatchHandler<State>
        ): void;
        registerRpc(id: string, func: RpcFunction): void;
    }
}
