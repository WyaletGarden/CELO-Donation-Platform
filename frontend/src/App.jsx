import { useState, useEffect } from 'react'
import { ethers } from 'ethers'
import './App.css'
import { FaHeart, FaDonate, FaUsers, FaClock, FaCheckCircle } from 'react-icons/fa'

// Contract ABI (cần thay bằng ABI thực tế sau khi deploy)
import DonationPlatformABI from './abi/DonationPlatform.json'

// Cấu hình
const CONTRACT_ADDRESS = import.meta.env.VITE_CONTRACT_ADDRESS || '' // Thay bằng địa chỉ contract sau khi deploy
const CUSD_ADDRESS = '0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1' // Alfajores/Celo Sepolia
const CELO_NETWORK = {
  chainId: '0xaef3', // 44787 in hex
  chainName: 'Celo Alfajores Testnet',
  nativeCurrency: {
    name: 'CELO',
    symbol: 'CELO',
    decimals: 18
  },
  rpcUrls: ['https://alfajores-forno.celo-testnet.org'],
  blockExplorerUrls: ['https://alfajores.celoscan.io']
}

function App() {
  const [provider, setProvider] = useState(null)
  const [signer, setSigner] = useState(null)
  const [contract, setContract] = useState(null)
  const [account, setAccount] = useState(null)
  const [campaigns, setCampaigns] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  // Debug: Log environment variables
  useEffect(() => {
    console.log('Contract Address:', CONTRACT_ADDRESS || 'Chưa cấu hình')
    console.log('ABI loaded:', DonationPlatformABI && DonationPlatformABI.length > 0 ? 'Yes' : 'No')
    if (!CONTRACT_ADDRESS) {
      // Chỉ hiển thị warning, không block app
      console.warn('⚠️ VITE_CONTRACT_ADDRESS chưa được cấu hình trong .env')
    }
  }, [])

  // Form states
  const [showCreateForm, setShowCreateForm] = useState(false)
  const [showDonateForm, setShowDonateForm] = useState(null) // campaignId

  // Connect wallet
  const connectWallet = async () => {
    try {
      if (typeof window.ethereum === 'undefined') {
        alert('Vui lòng cài đặt MetaMask!')
        return
      }

      // Request account access
      const accounts = await window.ethereum.request({
        method: 'eth_requestAccounts'
      })

      // Check if on Celo network
      const chainId = await window.ethereum.request({ method: 'eth_chainId' })
      if (chainId !== CELO_NETWORK.chainId) {
        try {
          await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: CELO_NETWORK.chainId }]
          })
        } catch (switchError) {
          // Network doesn't exist, add it
          if (switchError.code === 4902) {
            await window.ethereum.request({
              method: 'wallet_addEthereumChain',
              params: [CELO_NETWORK]
            })
          }
        }
      }

      const provider = new ethers.BrowserProvider(window.ethereum)
      const signer = await provider.getSigner()

      setProvider(provider)
      setSigner(signer)
      setAccount(accounts[0])

      // Chỉ tạo contract instance nếu có address, nếu không thì chỉ connect wallet
      if (CONTRACT_ADDRESS) {
        try {
          // First verify contract exists
          const code = await provider.getCode(CONTRACT_ADDRESS)
          if (!code || code === '0x') {
            setError(`⚠️ Không tìm thấy contract tại địa chỉ ${CONTRACT_ADDRESS} trên network hiện tại. Vui lòng: 1) Kiểm tra contract đã được deploy chưa, 2) Đảm bảo MetaMask đang ở Celo Alfajores (Chain ID: 44787)`)
            console.error('No contract code at address:', CONTRACT_ADDRESS)
            console.error('Current network chainId:', chainId)
            return
          }
          
          const contract = new ethers.Contract(CONTRACT_ADDRESS, DonationPlatformABI, signer)
          setContract(contract)
          loadCampaigns(contract)
        } catch (err) {
          console.warn('Could not create contract instance:', err)
          setError(`⚠️ Lỗi khi tạo contract instance: ${err.message || err}. Vui lòng kiểm tra lại VITE_CONTRACT_ADDRESS trong file .env`)
        }
      } else {
        // Cho phép connect wallet ngay cả khi chưa có contract address
        setError('⚠️ Contract address chưa được cấu hình. Bạn có thể kết nối ví nhưng chưa thể tương tác với contract. Thêm VITE_CONTRACT_ADDRESS vào file .env và restart server.')
      }
    } catch (err) {
      console.error('Error connecting wallet:', err)
      setError(err.message)
    }
  }

  // Load campaigns
  const loadCampaigns = async (contractInstance) => {
    try {
      if (!contractInstance) {
        console.warn('Contract instance not available')
        return
      }

      // Validate contract address
      if (!CONTRACT_ADDRESS || CONTRACT_ADDRESS === '' || !ethers.isAddress(CONTRACT_ADDRESS)) {
        setError('⚠️ Contract address không hợp lệ. Vui lòng cấu hình VITE_CONTRACT_ADDRESS trong file frontend/.env')
        console.error('Invalid contract address:', CONTRACT_ADDRESS)
        return
      }

      // Verify contract exists by checking code (if provider is available)
      if (provider) {
        try {
          const code = await provider.getCode(CONTRACT_ADDRESS)
          if (!code || code === '0x') {
            setError(`⚠️ Không tìm thấy contract tại địa chỉ ${CONTRACT_ADDRESS}. Vui lòng kiểm tra lại địa chỉ contract hoặc deploy contract trước.`)
            console.error('No contract code found at address:', CONTRACT_ADDRESS)
            return
          }
        } catch (codeErr) {
          console.warn('Could not verify contract code:', codeErr)
          // Continue anyway, the call will fail with a clearer error
        }
      }
      
      setLoading(true)
      
      // Try to call getTotalCampaigns with better error handling
      let totalCampaigns
      try {
        console.log('Calling getTotalCampaigns on contract:', CONTRACT_ADDRESS)
        totalCampaigns = await contractInstance.getTotalCampaigns()
        console.log('Total campaigns retrieved:', Number(totalCampaigns))
        
        // Validate the result
        if (totalCampaigns === null || totalCampaigns === undefined) {
          throw new Error('getTotalCampaigns returned null/undefined')
        }
      } catch (callErr) {
        console.error('Error calling getTotalCampaigns:', callErr)
        console.error('Error details:', {
          message: callErr.message,
          code: callErr.code,
          data: callErr.data,
          error: callErr.error
        })
        
        let errorMessage = `⚠️ Không thể đọc dữ liệu từ contract. `
        
        if (callErr.message && (callErr.message.includes('0x') || callErr.message.includes('BAD_DATA'))) {
          errorMessage += `Contract có thể chưa được deploy tại địa chỉ ${CONTRACT_ADDRESS} hoặc bạn đang ở sai network. `
        } else if (callErr.code === 'CALL_EXCEPTION' || callErr.error?.code === 'CALL_EXCEPTION') {
          errorMessage += `Không thể gọi contract. Có thể contract không tồn tại tại địa chỉ này. `
        } else {
          errorMessage += `Lỗi: ${callErr.message || callErr}. `
        }
        
        errorMessage += `Hãy kiểm tra: 1) Contract đã deploy chưa? 2) MetaMask đã chuyển sang Celo Alfajores (Chain ID: 44787) chưa? 3) Địa chỉ contract có đúng không?`
        
        setError(errorMessage)
        setLoading(false)
        return
      }
      
      const campaignList = []

      for (let i = 1; i <= totalCampaigns; i++) {
        try {
          const campaign = await contractInstance.getCampaign(i)
          const donations = await contractInstance.getCampaignDonations(i)
          
          // Calculate progress percentage
          const progress = campaign.goal > 0 ? Math.min((Number(campaign.raised) * 100) / Number(campaign.goal), 100) : 0
          
          // Calculate time remaining
          const currentTime = Math.floor(Date.now() / 1000)
          const timeRemaining = campaign.deadline > currentTime ? Number(campaign.deadline) - currentTime : 0

          campaignList.push({
            id: Number(campaign.id),
            title: campaign.title,
            name: campaign.title, // For compatibility with existing UI
            description: campaign.description,
            goal: campaign.goal,
            targetAmount: campaign.goal, // For compatibility
            raised: campaign.raised,
            raisedAmount: campaign.raised, // For compatibility
            deadline: campaign.deadline,
            goalReached: campaign.goalReached,
            active: campaign.active,
            isActive: campaign.active, // For compatibility
            disbursed: campaign.disbursed,
            withdrawn: campaign.disbursed, // For compatibility
            creator: campaign.creator,
            donorCount: Number(campaign.donorCount),
            createdAt: Number(campaign.createdAt),
            progress: progress,
            timeRemaining: timeRemaining,
            donationCount: donations.length
          })
        } catch (campaignErr) {
          console.warn(`Error loading campaign ${i}:`, campaignErr)
          // Skip invalid campaigns
        }
      }

      setCampaigns(campaignList)
    } catch (err) {
      console.error('Error loading campaigns:', err)
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  // Create campaign
  const handleCreateCampaign = async (e) => {
    e.preventDefault()
    if (!contract) return

    const formData = new FormData(e.target)
    const deadline = Math.floor(Date.now() / 1000) + parseInt(formData.get('durationDays')) * 24 * 60 * 60

    try {
      setLoading(true)
      const tx = await contract.createCampaign(
        formData.get('name'),
        formData.get('description'),
        ethers.parseEther(formData.get('targetAmount')),
        deadline
      )

      await tx.wait()
      await loadCampaigns(contract)
      setShowCreateForm(false)
      e.target.reset()
      alert('Chiến dịch đã được tạo thành công!')
    } catch (err) {
      console.error('Error creating campaign:', err)
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  // Donate
  const handleDonate = async (e, campaignId) => {
    e.preventDefault()
    if (!contract) return

    const formData = new FormData(e.target)
    const amount = ethers.parseEther(formData.get('amount'))

    try {
      setLoading(true)

      // Approve cUSD first (check current allowance first)
      const cUSDAbi = [
        'function approve(address spender, uint256 amount) returns (bool)',
        'function allowance(address owner, address spender) view returns (uint256)'
      ]
      const cUSDContract = new ethers.Contract(CUSD_ADDRESS, cUSDAbi, signer)
      
      // Check current allowance
      const currentAllowance = await cUSDContract.allowance(account, CONTRACT_ADDRESS)
      if (currentAllowance < amount) {
        const approveTx = await cUSDContract.approve(CONTRACT_ADDRESS, amount)
        await approveTx.wait()
      }

      // Donate
      const tx = await contract.donate(
        campaignId,
        amount
      )

      await tx.wait()
      await loadCampaigns(contract)
      setShowDonateForm(null)
      e.target.reset()
      alert('Quyên góp thành công!')
    } catch (err) {
      console.error('Error donating:', err)
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  // Auto Disburse (when goal is reached)
  const handleAutoDisburse = async (campaignId) => {
    if (!contract) return

    if (!confirm('Bạn có chắc muốn giải ngân tự động? (Chỉ khi đạt 100% mục tiêu)')) {
      return
    }

    try {
      setLoading(true)
      const tx = await contract.autoDisburse(campaignId)
      await tx.wait()
      await loadCampaigns(contract)
      alert('Giải ngân tự động thành công!')
    } catch (err) {
      console.error('Error auto disbursing:', err)
      setError(err.message)
      alert('Lỗi: ' + err.message)
    } finally {
      setLoading(false)
    }
  }

  // Manual Disburse (by creator, after deadline)
  const handleManualDisburse = async (campaignId) => {
    if (!contract) return

    if (!confirm('Bạn có chắc muốn giải ngân thủ công?')) {
      return
    }

    try {
      setLoading(true)
      const tx = await contract.manualDisburse(campaignId)
      await tx.wait()
      await loadCampaigns(contract)
      alert('Giải ngân thủ công thành công!')
    } catch (err) {
      console.error('Error manual disbursing:', err)
      setError(err.message)
      alert('Lỗi: ' + err.message)
    } finally {
      setLoading(false)
    }
  }

  // End Campaign
  const handleEndCampaign = async (campaignId) => {
    if (!contract) return

    if (!confirm('Bạn có chắc muốn kết thúc chiến dịch? (Chỉ khi đã hết hạn)')) {
      return
    }

    try {
      setLoading(true)
      const tx = await contract.endCampaign(campaignId)
      await tx.wait()
      await loadCampaigns(contract)
      alert('Kết thúc chiến dịch thành công!')
    } catch (err) {
      console.error('Error ending campaign:', err)
      setError(err.message)
      alert('Lỗi: ' + err.message)
    } finally {
      setLoading(false)
    }
  }

  const formatAddress = (addr) => {
    if (!addr) return ''
    return `${addr.slice(0, 6)}...${addr.slice(-4)}`
  }

  const formatTimeRemaining = (seconds) => {
    if (seconds === 0) return 'Đã hết hạn'
    const days = Math.floor(seconds / 86400)
    const hours = Math.floor((seconds % 86400) / 3600)
    if (days > 0) return `${days} ngày ${hours} giờ`
    return `${hours} giờ`
  }

  return (
    <div className="App">
      <header className="header">
        <h1><FaHeart /> Donation Campaign DApp</h1>
        {account ? (
          <div className="wallet-info">
            <span>Connected: {formatAddress(account)}</span>
            <button onClick={() => loadCampaigns(contract)}>Refresh</button>
          </div>
        ) : (
          <button onClick={connectWallet} className="connect-btn">
            Connect Wallet
          </button>
        )}
      </header>

      {error && (
        <div className="error-message">
          {error}
          <button onClick={() => setError(null)}>×</button>
        </div>
      )}

      <main className="main-content">
        {account && (
          <div className="actions">
            <button 
              onClick={() => setShowCreateForm(!showCreateForm)}
              className="btn-primary"
            >
              {showCreateForm ? 'Hủy' : '+ Tạo Chiến Dịch'}
            </button>
          </div>
        )}

        {showCreateForm && account && (
          <form onSubmit={handleCreateCampaign} className="campaign-form">
            <h2>Tạo Chiến Dịch Mới</h2>
            <input type="text" name="name" placeholder="Tên chiến dịch" required />
            <textarea name="description" placeholder="Mô tả chi tiết" required></textarea>
            <input type="number" name="targetAmount" placeholder="Mục tiêu (cUSD)" step="0.01" required />
            <input type="number" name="durationDays" placeholder="Thời hạn (ngày)" required />
            <button type="submit" disabled={loading}>
              {loading ? 'Đang tạo...' : 'Tạo Chiến Dịch'}
            </button>
          </form>
        )}

        <div className="campaigns-grid">
          {loading && campaigns.length === 0 ? (
            <div className="loading">Đang tải...</div>
          ) : campaigns.length === 0 ? (
            <div className="empty-state">
              <FaHeart size={64} />
              <p>Chưa có chiến dịch nào</p>
              {!account && <p>Kết nối ví để xem hoặc tạo chiến dịch</p>}
            </div>
          ) : (
            campaigns.map((campaign) => (
              <div key={campaign.id} className="campaign-card">
                {campaign.imageURL && (
                  <img src={campaign.imageURL} alt={campaign.name} className="campaign-image" />
                )}
                <div className="campaign-content">
                  <h2>{campaign.name}</h2>
                  <p className="description">{campaign.description}</p>
                  
                  <div className="progress-bar">
                    <div 
                      className="progress-fill" 
                      style={{ width: `${Math.min(campaign.progress, 100)}%` }}
                    ></div>
                  </div>
                  <div className="stats">
                    <span><FaDonate /> {ethers.formatEther(campaign.raisedAmount)} / {ethers.formatEther(campaign.targetAmount)} cUSD</span>
                    <span>{campaign.progress}%</span>
                  </div>

                  <div className="info-grid">
                    <div><FaUsers /> {campaign.donorCount} người ủng hộ</div>
                    <div><FaClock /> {formatTimeRemaining(campaign.timeRemaining)}</div>
                    {campaign.goalReached && <div className="goal-badge"><FaCheckCircle /> Đã đạt mục tiêu</div>}
                  </div>

                  {account && (
                    <div className="actions">
                      {showDonateForm === campaign.id ? (
                        <form onSubmit={(e) => handleDonate(e, campaign.id)} className="donate-form">
                          <input type="number" name="amount" placeholder="Số tiền (cUSD)" step="0.01" required />
                          <div className="form-actions">
                            <button type="submit" disabled={loading}>Quyên Góp</button>
                            <button type="button" onClick={() => setShowDonateForm(null)}>Hủy</button>
                          </div>
                        </form>
                      ) : (
                        <>
                          {!campaign.disbursed && campaign.active && (
                            <button 
                              onClick={() => setShowDonateForm(campaign.id)}
                              className="btn-donate"
                            >
                              <FaDonate /> Quyên Góp
                            </button>
                          )}
                          {account.toLowerCase() === campaign.creator.toLowerCase() && !campaign.disbursed && (
                            <div className="creator-actions">
                              {campaign.goalReached && (
                                <button 
                                  onClick={() => handleAutoDisburse(campaign.id)}
                                  className="btn-withdraw"
                                >
                                  Giải Ngân Tự Động
                                </button>
                              )}
                              {campaign.timeRemaining === 0 && (
                                <button 
                                  onClick={() => handleManualDisburse(campaign.id)}
                                  className="btn-withdraw"
                                >
                                  Giải Ngân Thủ Công
                                </button>
                              )}
                              {campaign.active && campaign.timeRemaining === 0 && (
                                <button 
                                  onClick={() => handleEndCampaign(campaign.id)}
                                  className="btn-refund"
                                >
                                  Kết Thúc Chiến Dịch
                                </button>
                              )}
                            </div>
                          )}
                        </>
                      )}
                    </div>
                  )}
                </div>
              </div>
            ))
          )}
        </div>
      </main>
    </div>
  )
}

export default App
