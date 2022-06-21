let givenYields = [];
let totalYieldGiven = 0;
let totalNFT = 0;

let totalUserWealth = 0;
let totalUserFutureWealth = 0;

const users = [];
const USER_COUNT = 10;
const MONTH_COUNT = 60;

const givenYields_MAX = 100;
const givenYields_MIN = 200;

class User {
    constructor () {
        this.nft = 100;
        this.wealth = 0;
        this.futureWealth = 0;
        this.lastClaimTime = 0;
    }

    claim () {
        let claimable = 0;
        for (let i = this.lastClaimTime; i < givenYields.length; ++i) {
            const givenYieldsClaimble = givenYields[i]/totalNFT*this.nft;
            claimable += givenYieldsClaimble;
        }

        this.wealth += claimable + this.futureWealth;
        this.futureWealth = 0;

        this.lastClaimTime = givenYields.length;
    }

    futureClaim () {
        let claimable = 0;
        for (let i = this.lastClaimTime; i < givenYields.length; ++i) {
            const givenYieldsClaimble = givenYields[i]/totalNFT*this.nft;
            claimable += givenYieldsClaimble;
        }

        this.futureWealth += claimable;
        this.lastClaimTime = givenYields.length;
    }

    transferTo(quantity) {
        if (this.nft < quantity) {
            return;
        }
        this.futureClaim();
        this.nft -= quantity;
    }

    transferFrom(quantity) {
        this.futureClaim();
        this.nft += quantity;
    }
}

for (let i = 0; i < USER_COUNT; ++i) {
    users.push(new User());
    totalNFT += users[i].nft;
}

for (let i = 0; i < MONTH_COUNT; ++i) {
    console.log("\x1b[33m%s\x1b[0m", `\n----------- Month: ${i} -----------`);

    const givenYieldsSum = Math.floor(Math.random() * (givenYields_MAX - givenYields_MIN) * 100) / 100 + givenYields_MIN;
    givenYields.push(givenYieldsSum)
    totalYieldGiven += givenYieldsSum;

    const givenYieldsValue = givenYieldsSum/totalNFT;
    console.log("\x1b[33m%s\x1b[0m",`\n----------- givenYieldsSum: ${givenYieldsSum}`);
    console.log("\x1b[33m%s\x1b[0m",`\n----------- givenYieldsValue: ${givenYieldsValue}`);

    for (let i = 0; i < USER_COUNT; ++i) {
        const randomUserID = Math.floor(Math.random() * (USER_COUNT-1));
        const randomQuantity = Math.floor(Math.random() * users[i].nft);
        if(randomQuantity>0 && users[i].nft > randomQuantity) {
            console.log(`\n user[${i}] transferTo user[${randomUserID}] : ${randomQuantity} NFTs`);
            users[i].transferTo(randomQuantity);
            users[randomUserID].transferFrom(randomQuantity);

            //random claim
            const randomClaim = Math.floor(Math.random()*2);
            if(randomClaim>0) {
                console.log("\x1b[31m%s\x1b[0m",`\n----------- randomClaim: user[${i}] claimed`);
                users[i].claim();
            }
        }
    }
}

console.log("\x1b[34m%s\x1b[0m", `\n----------- totalYieldGiven: ${totalYieldGiven}`);

// before Claim
totalUserWealth = 0;
totalUserFutureWealth = 0;
for (let i = 0; i < USER_COUNT; ++i) {
    totalUserWealth += users[i].wealth;
    totalUserFutureWealth += users[i].futureWealth;
}

console.log("\x1b[35m%s\x1b[0m", `\n----------- before Claim -----------`);
console.log("\x1b[35m%s\x1b[0m", `\n----------- totalUserWealth: ${totalUserWealth}`);
console.log("\x1b[35m%s\x1b[0m", `\n----------- totalUserFutureWealth: ${totalUserFutureWealth}`);
console.log("\x1b[35m%s\x1b[0m", `\n----------- total: ${totalUserWealth + totalUserFutureWealth}`);

// after Claim
totalUserWealth = 0;
totalUserFutureWealth = 0;
for (let i = 0; i < USER_COUNT; ++i) {
    users[i].claim();
    totalUserWealth += users[i].wealth;
    totalUserFutureWealth += users[i].futureWealth;
}

console.log("\x1b[33m%s\x1b[0m", `\n----------- after Claim -----------`);
console.log("\x1b[33m%s\x1b[0m", `\n----------- totalUserWealth: ${totalUserWealth}`);
console.log("\x1b[33m%s\x1b[0m", `\n----------- totalUserFutureWealth: ${totalUserFutureWealth}`);
console.log("\x1b[33m%s\x1b[0m", `\n----------- total: ${totalUserWealth + totalUserFutureWealth}`);




