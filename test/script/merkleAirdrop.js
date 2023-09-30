const keccak256 = require("keccak256");
const { MerkleTree } = require("merkletreejs")
const { ethers } = require("ethers");

function encodeLeaf(address, spots) {
    // Same as `abi.encodePacked` in Solidity
    return ethers.utils.defaultAbiCoder.encode(
      ["address", "uint64"], // The datatypes of arguments to encode
      [address, spots] // The actual values
    )
  }

// more at https://learnweb3.io/degrees/ethereum-developer-degree/senior/how-to-create-merkle-trees-for-airdrops/
async function main(){
    const args = process.argv.slice(2);
    const address1 = ethers.utils.getAddress(args[0]);
    const address2 = ethers.utils.getAddress(args[1]);
    const address3 = ethers.utils.getAddress(args[2]);
    const address4 = ethers.utils.getAddress(args[3]);
    const toPrint = args[4];
    const proofIndex = args[5];
      
    // Create an array of ABI-encoded elements to put in the Merkle Tree
    // const list = [leaf0, leaf1, leaf2, leaf3];
    const list = [
        encodeLeaf(address1, 2),
        encodeLeaf(address2, 2),
        encodeLeaf(address3, 2),
        encodeLeaf(address4, 2),
      ];
    // Using keccak256 as the hashing algorithm, create a Merkle Tree
    // We use keccak256 because Solidity supports it
    // We can use keccak256 directly in smart contracts for verification
    // Make sure to sort the tree so it can be reproduced deterministically each time
    const merkleTree = new MerkleTree(list, keccak256, {
      hashLeaves: true, // Hash each leaf using keccak256 to make them fixed-size
      sortPairs: true, // Sort the tree for determinstic output
      sortLeaves: true,
    });
    
    if (toPrint == "root") {
        // Compute the Merkle Root in Hexadecimal
        const root = merkleTree.getHexRoot();
        console.log(root);
    } else {
        const leaf = keccak256(encodeLeaf(address2, 2)) ;
        const proof = merkleTree.getHexProof(leaf); // Get the Merkle Proof
        console.log(proof[proofIndex]);
    }
}

main()
.then()
.catch((error) => {
    console.error(error);
    throw new Error("Exit: 1");
});