import "@stdlib/tvm-dicts";
import "errors";
import "storage";
import "messages";

const slotPrice: int = ton("100000");
const slotUpdatePrice: int = ton("10000");
const maxItemIndex: int = 40000;

fun deployNftItem(itemIndex: int, nftItemCode: cell, attachTonAmount: coins, buyer: address) {
    var initParams: NftItemInitAtDeployment = {
        ownerAddress: buyer
    };
    val deployMsg = createMessage({
        bounce: true,
        dest: calcDeployedNftItem(itemIndex, contract.getAddress(), nftItemCode),
        value: attachTonAmount,
        body: initParams,
    });
    // TODO send to blackhole
    reserveToncoinsOnBalance(slotPrice, RESERVE_MODE_INCREASE_BY_ORIGINAL_BALANCE | RESERVE_MODE_BOUNCE_ON_ACTION_FAIL);
    deployMsg.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
}

type AllowedMessageToNftCollection = DeployNft | UpdateSlotContent;

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedMessageToNftCollection.fromSlice(in.body);

    match (msg) {
        DeployNft => {
            var storage = lazy NftCollectionStorage.load();
            assert (storage.nextItemIndex < maxItemIndex) throw ERROR_INVALID_ITEM_INDEX;

            deployNftItem(storage.nextItemIndex, storage.nftItemCode, msg.attachTonAmount, in.senderAddress);
            storage.nextItemIndex += 1;
            storage.save();
        }
        UpdateSlotContent => {
            var storage = lazy NftCollectionStorage.load();
            var expectedAddress = calcDeployedNftItem(msg.index as uint64, contract.getAddress(), storage.nftItemCode);
            assert (expectedAddress.addressMatches(in.senderAddress)) throw ERROR_NOT_FROM_ITEM;

            // lets find config contract address from config
            var configParam = blockchain.configParam(0);
            var configAddressHash = configParam!.beginParse().preloadUint(256);
            var slot_index = -10000 - msg.index; // convert to negative index for slot

            // TODO send to blackhole
            reserveToncoinsOnBalance(slotUpdatePrice, RESERVE_MODE_INCREASE_BY_ORIGINAL_BALANCE | RESERVE_MODE_BOUNCE_ON_ACTION_FAIL);
            // send response to the sender
            var response = createMessage({
                value: 0,
                bounce: true,
                dest: (-1, configAddressHash),
                body: UpdateSlotContent {
                    queryId: msg.queryId,
                    index: slot_index,
                    newContent: msg.newContent
                }
            });
            response.send(SEND_MODE_CARRY_ALL_BALANCE | SEND_MODE_BOUNCE_ON_ACTION_FAIL);
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

struct (0x00) OnchainMetadataReply {
    data: dict
}

get fun get_collection_data(): CollectionDataReply {
    val storage = lazy NftCollectionStorage.load();

    return {
        nextItemIndex: storage.nextItemIndex,
        collectionMetadata: createEmptyCell(),
        adminAddress: createAddressNone()
    }
}

get fun get_nft_address_by_index(itemIndex: int): address {
    val storage = lazy NftCollectionStorage.load();
    val nftDeployed = calcDeployedNftItem(itemIndex, contract.getAddress(), storage.nftItemCode);
    return address.fromValidBuilder(nftDeployed.buildAddress());
}


get fun get_nft_content(itemIndex: int, individualNftContent: Cell<SnakeString>): Cell<OnchainMetadataReply> {
    val storage = lazy NftCollectionStorage.load();

    // construct a responce from "common content" and "individual content";
    // for example:
    // common content = "https://site.org/my-collection/"
    // individual nft = "my-picture-123.png"  (probably, a long string, snake-encoded)
    // result         = concatenation
    var propertiesDict: dict = createEmptyDict();
    propertiesDict.uDictSetRef(256, stringSha256("name"),
       beginCell()
            .storeUint(0, 8)
            .storeSlice("Slot: -")   
            .storeSlice(individualNftContent.beginParse())
            .endCell());
    propertiesDict.uDictSetRef(256, stringSha256("description"),
         beginCell()
            .storeUint(0, 8) 
            .storeSlice("This NFT represents TON Config Parameter Ownership")
            .endCell());
    return OnchainMetadataReply {
        data: propertiesDict
    }.toCell()
}
