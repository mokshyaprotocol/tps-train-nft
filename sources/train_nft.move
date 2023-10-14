address train_nft
{
    module train_nft
    {
        use std::signer;
        use std::bcs;
        use std::vector;
        use std::string::{Self, String};
        use aptos_framework::object;
        use aptos_token_objects::collection;
        use aptos_token_objects::token;
        use aptos_framework::account;
        use aptos_framework::aptos_account;
        use aptos_framework::coin::{Self};
        use aptos_framework::aptos_coin::AptosCoin;
        use std::option;
        
        /// The Module is not initiated
        const ENO_NOT_INITIATED:u64=0;

        const COLLECTION: vector<u8> = b"TPS Train";
        const DESCRIPTION: vector<u8> = b"Thank you for contributing to stress test Aptos Network."; 
        const URI: vector<u8> = b"ipfs://bafkreiaa2q526x2bjq73svffbooxqjboulsdlb3rghj5gfcdtp6qnhyqs4";


        struct TreasuryInfo has key {
            treasury_cap:account::SignerCapability,
            mints:u64,
        }

        fun init_module
        (
            account:&signer,
        )
        {
            let description = string::utf8(DESCRIPTION);
            let collection = string::utf8(COLLECTION);
            let uri = string::utf8(URI);
            let (_resource, resource_cap) = account::create_resource_account(account, bcs::to_bytes(&collection));
            let resource_signer_from_cap = account::create_signer_with_capability(&resource_cap);

            // unlimited supply token
            collection::create_unlimited_collection(
                &resource_signer_from_cap,
                description,
                collection,
                option::none(),
                uri,
            );
            move_to<TreasuryInfo>(account,
            TreasuryInfo{
                treasury_cap:resource_cap,
                mints:0,
            });
        }
        public entry fun mint_to(
            donator: &signer,
            receiver:address,
            amount:u64,  
        ) acquires TreasuryInfo
        {
            assert!(exists<TreasuryInfo>(@train_nft),ENO_NOT_INITIATED);
            let treasure_info = borrow_global_mut<TreasuryInfo>(@train_nft);
            let resource_signer_from_cap = account::create_signer_with_capability(&treasure_info.treasury_cap);
            let mint_position=treasure_info.mints+1;
            let token_name = string::utf8(COLLECTION);
            string::append(&mut token_name,string::utf8(b" #"));
            string::append(&mut token_name,num_str(mint_position));
            let constructor_ref = token::create_named_token(
                &resource_signer_from_cap,
                string::utf8(COLLECTION),
                string::utf8(DESCRIPTION),
                token_name,
                option::none(),
                string::utf8(URI),);
            let transfer_ref = object::generate_transfer_ref(&constructor_ref);
            let linear_transfer_ref = object::generate_linear_transfer_ref(&transfer_ref);
            object::transfer_with_ref(linear_transfer_ref, signer::address_of(donator));
            object::disable_ungated_transfer(&transfer_ref);
            aptos_account::transfer_coins<AptosCoin>(donator,receiver, amount); 
            treasure_info.mints=treasure_info.mints+1;
        }
        inline fun num_str(num: u64): String
        {
        let v1 = vector::empty();
        while (num/10 > 0){
            let rem = num%10;
            vector::push_back(&mut v1, (rem+48 as u8));
            num = num/10;
        };
        vector::push_back(&mut v1, (num+48 as u8));
        vector::reverse(&mut v1);
        string::utf8(v1)
    }

    }
}