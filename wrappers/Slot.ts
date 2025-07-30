import { Address, beginCell, Cell, Slice, Contract, contractAddress, ContractProvider, Sender, SendMode, toNano } from '@ton/core';

export class Slot implements Contract {
     static readonly OPCODES = {
        TRANSFER: 0x5fcc3d14,
        GET_STATIC_DATA: 0x2fcb26a2,
        UPDATE_SLOT_CONTENT: 0x50526e56,
    };

    constructor(readonly address: Address, readonly init?: { code: Cell; data: Cell }) {}

    static createFromAddress(address: Address) {
        return new Slot(address);
    }


    async sendTransferOwnership(
        provider: ContractProvider,
        via: Sender,
        opts: {
            queryId?: number;
            value: bigint;
            to: Address;
            responseTo?: Address;
            forwardAmount?: bigint;
            forwardBody?: Cell | Slice;
        }
    ) {
        const body = beginCell()
            .storeUint(Slot.OPCODES.TRANSFER, 32)
            .storeUint(opts.queryId ?? 0, 64)
            .storeAddress(opts.to)
            .storeAddress(opts.responseTo)
            .storeMaybeRef(null)
            .storeCoins(opts.forwardAmount ?? 0);

        if (opts.forwardBody instanceof Cell) {
            body.storeBit(1).storeRef(opts.forwardBody);
        } else {
            body.storeBit(0).storeSlice(opts.forwardBody ?? Cell.EMPTY.beginParse());
        }
        await provider.internal(via, {
            value: opts.value,
            body: body.endCell()
        });
    }

    async sendGetStaticData(provider: ContractProvider, via: Sender, opts: {
        queryId?: number;
        value: bigint;
    }) {
        await provider.internal(via, {
            value: opts.value,
            sendMode: SendMode.PAY_GAS_SEPARATELY,
            body: beginCell()
                .storeUint(Slot.OPCODES.GET_STATIC_DATA, 32)
                .storeUint(opts.queryId ?? 0, 64)
                .endCell()
        });
    }


    async updateSlotContent(provider: ContractProvider, via: Sender, opts: {
        queryId?: number;
        content: Cell;
    }) {
        await provider.internal(via, {
            value: toNano("10001"),
            sendMode: SendMode.PAY_GAS_SEPARATELY,
            body: beginCell()
                .storeUint(Slot.OPCODES.UPDATE_SLOT_CONTENT, 32)
                .storeUint(opts.queryId ?? 0, 64)
                .storeRef(opts.content)
                .endCell()
        });
    }

    async getNftData(provider: ContractProvider): Promise<{
        init: boolean;
        index: number;
        collectionAddress: Address;
        ownerAddress: Address | null;
        individualContent: Cell | null;
    }> {
        const { stack } = await provider.get('get_nft_data', []);

        return {
            init: stack.readBoolean(),
            index: stack.readNumber(),
            collectionAddress: stack.readAddress(),
            ownerAddress: stack.readAddressOpt(),
            individualContent: stack.readCellOpt()
        };
    }
}
