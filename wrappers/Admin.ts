import { Address, beginCell, Cell, Contract, contractAddress, ContractProvider, Sender, SendMode, toNano, TupleBuilder } from '@ton/core';

export type AdminConfig = {
    nftItemCode: Cell;
};

export function adminConfigToCell(config: AdminConfig): Cell {
    return beginCell().storeUint(0, 64)
                      .storeRef(config.nftItemCode)
           .endCell();
}

export class Admin implements Contract {
    static readonly OPCODES = {
        DEPLOY_NFT: 1,
    };

    constructor(readonly address: Address, readonly init?: { code: Cell; data: Cell }) {}

    static createFromAddress(address: Address) {
        return new Admin(address);
    }

    static createFromConfig(config: AdminConfig, code: Cell, workchain = -1) {
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

    async sendDeployNft(
        provider: ContractProvider,
        via: Sender,
        opts: {
            attachTonAmount: bigint;
            queryId?: number;
        },
    ) {
        await provider.internal(via, {
            value: toNano('100000') + opts.attachTonAmount,
            sendMode: SendMode.PAY_GAS_SEPARATELY,
            body: beginCell()
                .storeUint(Admin.OPCODES.DEPLOY_NFT, 32)
                .storeUint(opts.queryId ?? 0, 64)
                .storeCoins(opts.attachTonAmount)
                .endCell(),
        });
    }

    async getSlotAddressByIndex(provider: ContractProvider, index: number): Promise<Address> {
        const builder = new TupleBuilder();
        builder.writeNumber(index);

        const { stack } = await provider.get('get_nft_address_by_index', builder.build());

        return stack.readAddress();
    }
}
