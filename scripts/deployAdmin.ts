import { toNano } from '@ton/core';
import { Admin } from '../wrappers/Admin';
import { compile, NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const admin = provider.open(Admin.createFromConfig({}, await compile('Admin')));

    await admin.sendDeploy(provider.sender(), toNano('0.05'));

    await provider.waitForDeploy(admin.address);

    // run methods on `admin`
}
