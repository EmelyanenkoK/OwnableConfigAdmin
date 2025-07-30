import "storage"

struct NftItemInitAtDeployment {
    ownerAddress: address
}

struct (0x00000001) DeployNft {
    queryId: uint64
    attachTonAmount: coins
}


struct (0x2fcb26a2) RequestStaticData {
    queryId: uint64
}

struct (0x8b771735) ResponseStaticData {
    queryId: uint64
    itemIndex: uint256
    collectionAddress: address
}

struct (0x05138d91) NotificationForNewOwner {
    queryId: uint64
    oldOwnerAddress: address
    payload: RemainingBitsAndRefs
}

struct (0xd53276db) ReturnExcessesBack {
    queryId: uint64
}

struct (0x5fcc3d14) AskToChangeOwnership {
    queryId: uint64
    newOwnerAddress: address
    sendExcessesTo: address
    customPayload: dict
    forwardTonAmount: coins
    forwardPayload: RemainingBitsAndRefs
}

struct (0x50526e56) UpdateSlotContent {
    queryId: uint64,
    index: int32,
    newContent: cell
}