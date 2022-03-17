const moment = require('moment');
const env = require('../env.json')['dev'];

const readline = require("readline");
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function prompt (message) {
  return new Promise((resolve, reject) => {
    rl.question(message, function(result) {
      resolve(result);
    });
  })
}

async function showWalletInfo(address){
 
}

async function addPermission(admin, addressArr){
  await hardhatContract.connect(admin).addToWhitelisted(addressArr)
}

async function main () {
  await showWalletInfo(usdmBuyer.address);

  while (true) {
    const command = await prompt('??? What do you want? (Choose number in below list) \n 1.Show my wallet assests \n 2.Buy MEI \n 3.Exit \n Your choice: ');
    switch (command) {
      case '3':{
        process.exit();
        break;
      }
      default: {
        break;
      }
    }
  }  
}

main();

