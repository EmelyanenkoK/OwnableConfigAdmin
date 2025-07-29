import "@stdlib/tvm-dicts";
import "errors";
import "storage";
import "messages";

fun deployNftItem(itemIndex: int, nftItemCode: cell, attachTonAmount: coins, buyer: address) {
    var initParams: NftItemInitAtDeployment = {
        ownerAddress: contract.getAddress()
    };
    val deployMsg = createMessage({
        bounce: true,
        dest: calcDeployedNftItem(itemIndex, contract.getAddress(), nftItemCode),
        value: attachTonAmount,
        body: initParams,
    });
    // TODO send to blackhole
    reserveToncoinsOnBalance(ton("100000"), RESERVE_MODE_INCREASE_BY_ORIGINAL_BALANCE);
    deployMsg.send(SEND_MODE_PAY_FEES_SEPARATELY | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
}

type AllowedMessageToNftCollection = DeployNft;

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToNftCollection.fromSlice(in.body);

    match (msg) {
        DeployNft => {
            var storage = lazy NftCollectionStorage.load();

            deployNftItem(storage.nextItemIndex, storage.nftItemCode, msg.attachTonAmount, in.senderAddress);
            storage.nextItemIndex += 1;
            storage.save();
        }
        else => {
            // ignore empty messages, "wrong opcode" for others
            assert (in.body.isEmpty()) throw 0xFFFF
        }
    }
}



struct CollectionDataReply {
    nextItemIndex: int
    collectionMetadata: cell
    adminAddress: address
}

struct (0x01) OffchainMetadataReply {
    string: SnakeString
}

get fun get_collection_data(): CollectionDataReply {
    val storage = lazy NftCollectionStorage.load();
    val content = lazy storage.content.load();

    return {
        nextItemIndex: storage.nextItemIndex,
        collectionMetadata: content.collectionMetadata,
        adminAddress: storage.adminAddress,
    }
}

get fun get_nft_address_by_index(itemIndex: int): address {
    val storage = lazy NftCollectionStorage.load();
    val nftDeployed = calcDeployedNftItem(itemIndex, contract.getAddress(), storage.nftItemCode);
    return address.fromValidBuilder(nftDeployed.buildAddress());
}


get fun get_nft_content(itemIndex: int, individualNftContent: Cell<SnakeString>): Cell<OffchainMetadataReply> {
    val storage = lazy NftCollectionStorage.load();
    val content = lazy storage.content.load();

    // construct a responce from "common content" and "individual content";
    // for example:
    // common content = "https://site.org/my-collection/"
    // individual nft = "my-picture-123.png"  (probably, a long string, snake-encoded)
    // result         = concatenation
    return OffchainMetadataReply {
        string: beginCell()
            .storeSlice("This NFT is TON Config Parameter Ownership right for Slot: -")   // assume it's short (no refs)
            .storeRef(individualNftContent)             // so, it's the first ref (snake encoding)
            .endCell().beginParse()
    }.toCell()
}
