import Web3 from "web3"
import { newKitFromWeb3 } from "@celo/contractkit"
import BigNumber from "bignumber.js"
import marketplaceAbi from "../contract/marketplace.abi.json"
import erc20Abi from "../contract/erc20.abi.json"

const ERC20_DECIMALS = 18
const MPContractAddress = "0xe961b5A406C3Db9920aA369eaf4e17BDd79053c8"
const cUSDContractAddress = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1" //Erc20 contract address

let kit //contractkit
let contract // contract variable
let listedSeeds = [] // array of event lists


//Connects the wallet gets the account and initializes the contract
const connectCeloWallet = async function () {
  //checks if wallet is avaliable and gets the account.
  if (window.celo) {
    notification("⚠️ Please approve this DApp to use it.")
    try {
      await window.celo.enable()
      notificationOff()

      const web3 = new Web3(window.celo)
      kit = newKitFromWeb3(web3)

      const accounts = await kit.web3.eth.getAccounts()
      kit.defaultAccount = accounts[0]

      contract = new kit.web3.eth.Contract(marketplaceAbi, MPContractAddress)
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
    notificationOff()
  }
  // if wallet is not avaliable excute enable the notification
  else {
    notification("⚠️ Please install the CeloExtensionWallet.")
  }
}

async function approve(_price) {
  const cUSDContract = new kit.web3.eth.Contract(erc20Abi, cUSDContractAddress)

  const result = await cUSDContract.methods
    .approve(MPContractAddress, _price)
    .send({ from: kit.defaultAccount })
  return result
}


// gets the balance of the connected account
const getBalance = async function () {
  const totalBalance = await kit.getTotalBalance(kit.defaultAccount)
  // gets the balance in cUSD
  const cUSDBalance = totalBalance.cUSD.shiftedBy(-ERC20_DECIMALS).toFixed(2)
  document.querySelector("#balance").textContent = cUSDBalance
}


// an async function used to get the listed seeds.
const getListedSeeds = async function() {
// a smartcontract call used to get listed seed length.
  const listedSeedLength = await contract.methods.getListedSeedLength().call()

  //initializing listSeed array
  const _listedSeeds = []

  //  function that loops through all the listSeeds.
  for (let i = 0; i < listedSeedLength; i++) {
    let seed = new Promise(async (resolve, reject) => {

  // a smartcontract call used to get listed seed by id.
      let p = await contract.methods.getListedSeedById(i).call()
      resolve({
        index: i,
        owner: p[0],
        seedName: p[1],
        seedImgUrl: p[2],
        seedDetails: p[3],
        seedLocation: p[4],
        price: new BigNumber(p[5])
      })
    })

    // push the items on the _listedSeed array
    _listedSeeds.push(seed)
  }

  // resolves all promise
  listedSeeds = await Promise.all(_listedSeeds)
  renderProductTemplate()
}


// function used to render a html template of listed seeds.
function renderProductTemplate() {
  document.getElementById("marketplace").innerHTML = ""
  if (listedSeeds) {
  listedSeeds.forEach((seed) => {
    if (seed.owner != "0x0000000000000000000000000000000000000000") {
    const newDiv = document.createElement("div")
    newDiv.className = "col-md-3"
    newDiv.innerHTML = productTemplate(seed)
    document.getElementById("marketplace").appendChild(newDiv)
  }
  })}
}

// function that create a html template of listed seeds
function productTemplate(seed) {
  return `
 <div class="card mb-4">
      <img class="card-img-top" src="${seed.seedImgUrl}" alt="...">
  <div class="card-body text-left p-3 position-relative">
        <div class="translate-middle-y position-absolute top-0 end-0"  id="${seed.index}">
        ${identiconTemplate(seed.owner)}
        </div>
        <p class="card-title  fw-bold mt-2 text-uppercase">${seed.seedName}</p>
        <p class="mt-2 text-left fs-6">
           ${new BigNumber(seed.price).shiftedBy(-ERC20_DECIMALS).toFixed(2)} cUSD
        </p>
        <p class="card-text mt-4">
           <div> <a class="btn btn-md btn-success view"
           id="${seed.index}" style="width:100%;">View More</a></div>
          </div>
    </div>
    `
}

// function  that creates an icon using the contract address of the owner
function identiconTemplate(_address) {
  const icon = blockies
    .create({
      seed: _address,
      size: 5,
      scale: 10,
    })
    .toDataURL()

  return `
  <div class="rounded-circle overflow-hidden d-inline-block border border-white border-2 shadow-sm m-0">
    <a href="https://alfajores-blockscout.celo-testnet.org/address/${_address}/transactions"
        target="_blank">
        <img src="${icon}" width="40" alt="${_address}">
    </a>
  </div>
  `
}


// function to create a notification bar
function notification(_text) {
  document.querySelector(".alert").style.display = "block"
  document.querySelector("#notification").textContent = _text
}


// function to turn off notification bar based on some conditions
function notificationOff() {
  document.querySelector(".alert").style.display = "none"
}


// initialization of functions when the window is loaded.
window.addEventListener("load", async () => {
  notification("⌛ Loading...")
  await connectCeloWallet()
  await getBalance()
  await getListedSeeds()
  notificationOff()
  });


// function used to list a seed on the blockchain.
document
  .querySelector("#postEventBtn")
  .addEventListener("click", async (e) => {

    const params = [
      document.getElementById("seedName").value,
      document.getElementById("seedImgUrl").value,
      document.getElementById("seedDetails").value,
      document.getElementById("seedLocation").value,
      new BigNumber(document.getElementById("newPrice").value)
      .shiftedBy(ERC20_DECIMALS)
      .toString()
    ]
    notification(`⌛ Posting your event to the blockchain please wait...`)
    try {
      const result = await contract.methods
        .listSeed(...params)
        .send({ from: kit.defaultAccount })
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
    notification(`🎉 Congrats event successfully added`)
    notificationOff()
    getListedSeeds()
  })



// implements various functionalities
document.querySelector("#marketplace").addEventListener("click", async (e) => {
    if(e.target.className.includes("view")){
      const _id = e.target.id;
      let eventData;
      let attendees = [];

      // function to get list of attendess on the smart contract.
      try {
          eventData = await contract.methods.getListedSeedById(_id).call();
          // attendees = await contract.methods.getAttendees(_id).call();
          let myModal = new bootstrap.Modal(document.getElementById('addModal1'), {backdrop: 'static', keyboard: false});
          myModal.show();


// stores the timestamp of the event date.
var eventTimeStamp= parseInt(eventData[4])

// converts timestamp to milliseconds.
var convertToMilliseconds = eventTimeStamp * 1000;

// create an object for it.
var dateFormat= new Date(convertToMilliseconds);


// displays events details on the modal
document.getElementById("modalHeader").innerHTML = `
<div class="card">
  <img class="card-img-top"
  src="${eventData[2]}"
  alt="image pic" style={{width: "100%", objectFit: "cover"}} />
  <div class="card-body">
    <p class="card-title fs-6 fw-bold mt-2 text-uppercase">${eventData[1]}</p>
    <p  style="font-size : 12px;">
      <span style="display : block;" class="text-uppercase fw-bold">Seed Description: </span>
      <span class="">${eventData[3]}</span>
    </p>

        <p  style="font-size : 12px;">
          <span style="display : block;" class="text-uppercase fw-bold">Soil Compactiblity: </span>
          <span class="">${eventData[4]}</span>
        </p>

        <p class="card-text mt-2" style="font-size : 12px;">
          <span style="display : block;" class="text-uppercase fw-bold">location: </span>
          <span >${eventData[4]}</span>
        </p>
        <div class="d-grid gap-2">
          <a class="btn btn-lg text-white bg-success buyBtn fs-6 p-3"
          id=${_id}
          >
            Buy for ${new BigNumber(eventData[5]).shiftedBy(-ERC20_DECIMALS).toFixed(2)} cUSD
          </a>
        </div>
  </div>
</div>

  `
    }
    catch (error) {
      notification(`⚠️ ${error}.`)
    }
    notificationOff()
  }
})

document.querySelector("#addModal1").addEventListener("click", async (e) => {
    if (e.target.className.includes("buyBtn")) {
      const index = e.target.id

      var _price =  new BigNumber(listedSeeds[index].price)
      var _seedName = listedSeeds[index].seedName
      var _seedImgUrl = listedSeeds[index].seedImgUrl

      notification("⌛ Waiting for payment approval...")
      try {
        await approve(listedSeeds[index].price)
      } catch (error) {
        notification(`⚠️ ${error}.`)
      }
      
      notification(`⌛ Awaiting payment for "${listedSeeds[index].seedName}"...`)
      try {
        const result = await contract.methods
          .buySeed(index, _seedName, _seedImgUrl, _price)
          .send({ from: kit.defaultAccount })
        notification(`🎉 You successfully bought "${listedSeeds[index].seedName}".`)
        getListedSeeds()
        getBalance()
      } catch (error) {
        notification(`⚠️ ${error}.`)
      }
    }

  })


  document.querySelector("#tabs").addEventListener("click", async (e) => {
      if (e.target.className.includes("showpurchased")) {
        document.getElementById("marketplace").classList.add("d-none");
        document.getElementById("purchasedProduct").classList.remove("d-none");

        var resultx;

        notification(`⌛ Processing your request please wait ...`)

        try {
           resultx = await contract.methods.getPurchasedSeeds().call();
          notification(`🎉 You are now one of the attendee .`)
console.log(resultx)

          if (resultx.length) {
        resultx.forEach((item) => {
                document.getElementById(`purchasedProduct`).innerHTML +=
                `
                <div class="card col-md-12  mb-4">
                <div class="card-body row">
                <div class="col-md-4">
                <img
                src="${item[2]}"
                alt="image pic" style={{width: "100%", objectFit: "cover"}} />
                    </div>

                    <div class="col-md-8">
                    <p class="card-text mt-2 d-flex justify-content-between" style="font-size : 12px;">
                      <span style="display : block;" class="text-uppercase fw-bold">Seed Name: </span>
                      <span >${item[1]}</span>
                    </p>

                    <p class="card-text mt-2 d-flex justify-content-between" style="font-size : 12px;">
                      <span style="display : block;" class="text-uppercase fw-bold">Soil Compactiblity: </span>
                      <span >${item[1]}</span>
                    </p>

                    <p class="card-text mt-2 d-flex justify-content-between" style="font-size : 12px;">
                      <span style="display : block;" class="text-uppercase fw-bold">Price: </span>
                      <span >${item[1]}</span>
                    </p>
                      </div>
                    </div>
                  </div>`
                  ;
              })
      } else{
        document.getElementById(`purchasedProduct`).innerHTML += `<p class="text-center">no attendee yet...</p>`;
      };

        } catch (error) {
          notification(`⚠️ ${error}.`)
        }
        // notificationOff()
        console.log(resultx[0][1])
        getListedSeeds()
        // document.getElementById("marketplace").innerHTML += `<p>Hello</p>`
      }

      else if (e.target.className.includes("showProducts")) {
        document.getElementById("marketplace").classList.remove("d-none");
        document.getElementById("purchasedProduct").classList.add("d-none");
      }
})
