import { Address, beginCell, Cell, Contract, contractAddress, ContractProvider, Sender, SendMode } from '@ton/core';

export type AdminConfig = {};

export function adminConfigToCell(config: AdminConfig): Cell {
    return beginCell().endCell();
}

export class Admin implements Contract {
    constructor(readonly address: Address, readonly init?: { code: Cell; data: Cell }) {}

    static createFromAddress(address: Address) {
        return new Admin(address);
    }

    static createFromConfig(config: AdminConfig, code: Cell, workchain = 0) {
        const data = adminConfigToCell(config);
        const init = { code, data };
        return new Admin(contractAddress(workchain, init), init);
    }

    async sendDeploy(provider: ContractProvider, via: Sender, value: bigint) {
        await provider.internal(via, {
            value,
            sendMode: SendMode.PAY_GAS_SEPARATELY,
            body: beginCell().endCell(),
        });
    }
}
