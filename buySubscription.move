module buySubscription::payment_subscription {
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;

    struct PaymentPlan has key {
        service_provider: address,
        client: address,
        fee: u64,
        period: u64,
        last_paid: u64,
    }

    public entry fun init_payment_plan(
        service_provider: &signer,
        client: address,
        fee: u64,
        period: u64
    ) {
        let provider_address = signer::address_of(service_provider);
        
        let payment_plan = PaymentPlan {
            service_provider: provider_address,
            client,
            fee,
            period,
            last_paid: timestamp::now_seconds(),
        };

        move_to(service_provider, payment_plan);
    }

    public entry fun execute_payment(client: &signer) acquires PaymentPlan {
        let client_address = signer::address_of(client);
        
        let payment_plan = borrow_global_mut<PaymentPlan>(client_address);
        
        let current_timestamp = timestamp::now_seconds();
        assert!(current_timestamp >= payment_plan.last_paid + payment_plan.period, 1);

        let payment = coin::withdraw<AptosCoin>(client, payment_plan.fee);
        coin::deposit(payment_plan.service_provider, payment);

        payment_plan.last_paid = current_timestamp;
    }

    public entry fun terminate_payment_plan(client: &signer) acquires PaymentPlan {
        let client_address = signer::address_of(client);
        
        let PaymentPlan { service_provider: _, client: _, fee: _, period: _, last_paid: _ } = 
            move_from<PaymentPlan>(client_address);
    }
}
