facebook = {
  provider: 'facebook',
  uid: '12345',
  info: {
    email: 'examplar@example.com',
    name: 'New User'
  },
  credentials: {
    token: "asd;lkfjas;dflkjasdfasdfha;vznxfhjasd;lfkhaweiuha;sdlkfjasdf",
    expires: true,
    expires_at: 1.month.from_now.to_i
  }
}

gplus = {
  provider: 'gplus',
  uid: '12345',
  info: {
    email: 'examplar@example.com',
    name: 'New User'
  },
  credentials: {
    token: "asd;lkfjas;dflkjasdfasdfha;vznxfhjasd;lfkhaweiuha;sdlkfjasdf",
    expires: true,
    expires_at: 1.month.from_now.to_i
  }
}

facebook_no_email = facebook.dup
facebook_no_email[:info].delete(:email)

OmniAuth.config.add_mock(:facebook, facebook)
OmniAuth.config.add_mock(:facebook_no_email, facebook_no_email)
OmniAuth.config.add_mock(:gplus, gplus)
