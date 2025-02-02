## Crowdfunding ERC20 contract

URL: https://www.rareskills.io/post/beginner-solidity-projects

Challenge:

> Your contract should have a createFundraiser() function with a goal and a deadline as arguments. Donators can donate() to a given fundraiserId. If the goal is reached before the deadline, the wallet that called createFundraiser() can withdraw() all the funds associated with that campaign. Otherwise, if the deadline passes without reaching the goal, the donators can withdraw their donation. Build a contract that supports Ether and another that supports ERC20 tokens.
Some corner cases to think about:
> - what if the same address donates multiple times?
> - what if the same address donates to multiple different campaigns?

## Usage

### Install

```shell
$ make install
```

### Test

```shell
$ make test
```
