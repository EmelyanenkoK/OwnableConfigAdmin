import { toNano, beginCell } from '@ton/core';
import { Admin } from '../wrappers/Admin';
import { Slot } from '../wrappers/Slot';
import { compile, NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {

    const slotCode = await compile('Slot');
    const admin = provider.open(Admin.createFromConfig({nftItemCode:slotCode}, await compile('Admin')));

    await admin.sendDeploy(provider.sender(), toNano('10.0'));

    await provider.waitForDeploy(admin.address);

    await admin.sendDeployNft(provider.sender(), {attachTonAmount: toNano("11")})
    
    var nftAddress = await admin.getSlotAddressByIndex(0);

    await provider.waitForDeploy(nftAddress);

    const slot = provider.open(Slot.createFromAddress(nftAddress));
 
    console.log(slot);

    await slot.sendUpdateSlotContent(provider.sender(), {index: 0, content: beginCell().endCell()});

    // run methods on `admin`
}
