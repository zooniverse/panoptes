OmniAuth.config.add_mock(:facebook, 
                         { provider: 'facebook',
                           uid: '12345',
                           info: {
                             email: 'examplar@example.com',
                             name: 'New User'
                           }
})

OmniAuth.config.add_mock(:facebook_no_email,
                         {  provider: 'facebook',
                            uid: '12345',
                            info: {
                              name: 'New User'
                            }
})
