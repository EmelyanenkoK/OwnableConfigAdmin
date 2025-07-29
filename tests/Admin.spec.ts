import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { Cell, toNano } from '@ton/core';
import { Admin } from '../wrappers/Admin';
import '@ton/test-utils';
import { compile } from '@ton/blueprint';

describe('Admin', () => {
    let code: Cell;

    beforeAll(async () => {
        code = await compile('Admin');
    });

    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let admin: SandboxContract<Admin>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        admin = blockchain.openContract(Admin.createFromConfig({}, code));

        deployer = await blockchain.treasury('deployer');

        const deployResult = await admin.sendDeploy(deployer.getSender(), toNano('0.05'));

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: admin.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and admin are ready to use
    });
});
