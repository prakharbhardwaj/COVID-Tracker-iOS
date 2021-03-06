//
//  PetitionTableViewController.swift
//  JSONCodables
//
//  Created by Prakhar Prakash Bhardwaj on 15/11/19.
//  Copyright © 2019 Prakhar Prakash Bhardwaj. All rights reserved.
//

import UIKit

class PetitionTableViewController: VersionUpdate {
    
    var lastUpdate = Int(Date().timeIntervalSince1970)
    var now = Int(Date().timeIntervalSince1970)
    var petetions = CovidData()
    var firstSection = CovidData()
    var sorting = "cases"
    var buttonChecked: ButtonChecked = .first
    let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView.init(style: .medium)
    var dateString = ""
    
    enum ButtonChecked {
        case first
        case second
        case third
        case forth
        case fifth
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshBtn = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshNavDb))
        
        let sortBtn = UIBarButtonItem(image: UIImage(systemName: "line.horizontal.3.decrease.circle"), style: .plain, target: self, action: #selector(sortButton))
        
        navigationItem.leftBarButtonItems = [sortBtn]
        navigationItem.rightBarButtonItems = [refreshBtn]
        
        self.generateAPISession()
        self.generateSession()
        self.registerNib()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(refreshDb), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    func loading(){
        DispatchQueue.main.async {
            let refreshBarButton: UIBarButtonItem = UIBarButtonItem(customView: self.activityIndicator)
            self.navigationItem.rightBarButtonItem = refreshBarButton
            self.navigationItem.title = "Loading..."
            self.activityIndicator.startAnimating()
        }
    }
    
    func stopLoading(){
        DispatchQueue.main.async {
            self.navigationItem.title = "COVID-19"
            self.activityIndicator.stopAnimating()
            let refreshBtn = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshNavDb))
            self.navigationItem.rightBarButtonItems = [refreshBtn]
            self.tableView.isUserInteractionEnabled = true
        }
    }
    
    func registerNib(){
        let nib = UINib(nibName: "PetitionTableViewCell", bundle: nil)
        let nib2 = UINib(nibName: "IndiaDetailCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "PetitionTableViewCell")
        tableView.register(nib2, forCellReuseIdentifier: "IndiaDetailCell")
    }
    
    @objc func refreshDb(){
        now = Int(Date().timeIntervalSince1970)
        if (now - lastUpdate >= 600){
            DispatchQueue.main.async {
                self.generateSession()
            }
        }else{
            print("Do nothing")
        }
    }
    
    @objc func refreshNavDb(){
        DispatchQueue.main.async {
            self.generateSession()
        }
    }
    
    //Sort button on navigation:
    @objc func sortButton() {
        
        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let mostcases = UIAlertAction(title: "Most Cases", style: .default, handler: { (action) in
            DispatchQueue.main.async {
                self.sorting = "cases"
                self.buttonChecked = .first
                self.generateSortSession()
            }
        })
        
        ac.addAction(mostcases)
        
        let mostdeaths = UIAlertAction(title: "Most Deaths", style: .default, handler: { (action) in
            DispatchQueue.main.async {
                self.sorting = "deaths"
                self.buttonChecked = .second
                self.generateSortSession()
            }
        })
        ac.addAction(mostdeaths)
        
        let mostrecovrs = UIAlertAction(title: "Most Recovers", style: .default, handler: { (action) in
            DispatchQueue.main.async {
                self.sorting = "recovers"
                self.buttonChecked = .third
                self.generateSortSession()
            }
        })
        ac.addAction(mostrecovrs)
        
        let newcases = UIAlertAction(title: "New Cases", style: .default, handler: { (action) in
            DispatchQueue.main.async {
                self.sorting = "newcases"
                self.buttonChecked = .forth
                self.generateSortSession()
            }
        })
        ac.addAction(newcases)
        
        let pastcases = UIAlertAction(title: "Yesterday's Cases", style: .default, handler: { (action) in
            DispatchQueue.main.async {
                self.buttonChecked = .fifth
                self.generatePastSession()
            }
        })
        ac.addAction(pastcases)
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        switch buttonChecked {
        case .first:
            mostcases.setValue(true, forKey: "checked")
            break
        case .second:
            mostdeaths.setValue(true, forKey: "checked")
            break
        case .third:
            mostrecovrs.setValue(true, forKey: "checked")
            break
        case .forth:
            newcases.setValue(true, forKey: "checked")
            break
        case .fifth:
            pastcases.setValue(true, forKey: "checked")
            break
        }
        
        present(ac, animated: true)
    }
    
    func generateSession() {
        getdataApi { (res) in
            switch res {
            case .success(let jsonResult):
                DispatchQueue.main.async {
                    self.buttonChecked = .first
                    self.now = Int(Date().timeIntervalSince1970)
                    self.lastUpdate = self.now
                    self.getCurrTime()
                    self.tableView.isUserInteractionEnabled = false
                    self.petetions.removeAll()
                    self.firstSection.removeAll()
                    self.petetions = jsonResult as? CovidData ?? []
                    let inIndex = self.petetions.firstIndex{$0.country == "India"}
                    let totIndex = self.petetions.firstIndex{$0.country == "World"}
                    self.firstSection.append(self.petetions[totIndex!])
                    self.firstSection.append(self.petetions[inIndex!])
                    print(self.firstSection)
                    self.tableView.reloadData()
                    self.stopLoading()
                    self.showToast(message: "Feed updated")
                }
            case .failure(let err):
                print("Failed to fetch courses", err.localizedDescription)
                self.stopLoading()
                DispatchQueue.main.async {
                    let ac = UIAlertController(title: "Oops!", message: "Please check your internet connection", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                    self.present(ac, animated: true, completion: nil)
                }
            }
        }
    }
    
    func getdataApi(completion: @escaping (Result<Any, Error>) -> Void) {
        self.loading()
        
        let urlString = "\(API_URL)/covid19"
        let urlPath = URL(string: urlString)!
        let urlRequest = URLRequest(url: urlPath)
        
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, _, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            
            guard let data = data else { return }
            do {
                let courses = try JSONDecoder().decode(CovidData.self, from: data)
                completion(.success(courses))
            } catch let jsonError {
                completion(.failure(jsonError))
            }        }
        task.resume()
    }
    
    func generateSortSession() {
        getSortDataApi { (res) in
            switch res {
            case .success(let jsonResult):
                DispatchQueue.main.async {
                    self.now = Int(Date().timeIntervalSince1970)
                    self.lastUpdate = self.now
                    self.getCurrTime()
                    self.tableView.isUserInteractionEnabled = false
                    self.petetions.removeAll()
                    self.firstSection.removeAll()
                    self.petetions = jsonResult as? CovidData ?? []
                    let inIndex = self.petetions.firstIndex{$0.country == "India"}
                    let totIndex = self.petetions.firstIndex{$0.country == "World"}
                    self.firstSection.append(self.petetions[totIndex!])
                    self.firstSection.append(self.petetions[inIndex!])
                    print(self.firstSection)
                    self.tableView.reloadData()
                    self.stopLoading()
                    self.showToast(message: "Feed updated")
                }
            case .failure(let err):
                print("Failed to fetch courses", err.localizedDescription)
                self.stopLoading()
                DispatchQueue.main.async {
                    let ac = UIAlertController(title: "Oops!", message: "Please check your internet connection", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                    self.present(ac, animated: true, completion: nil)
                }
            }
        }
    }
    
    func getSortDataApi(completion: @escaping (Result<Any, Error>) -> Void) {
        self.loading()
        
        let urlString = "\(API_URL)/covid19/sort?sortby=\(self.sorting)"
        let urlPath = URL(string: urlString)!
        let urlRequest = URLRequest(url: urlPath)
        
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, _, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            
            guard let data = data else { return }
            do {
                let courses = try JSONDecoder().decode(CovidData.self, from: data)
                completion(.success(courses))
            } catch let jsonError {
                completion(.failure(jsonError))
            }        }
        task.resume()
    }
    
    func generatePastSession() {
        getPastDataApi { (res) in
            switch res {
            case .success(let jsonResult):
                DispatchQueue.main.async {
                    self.now = Int(Date().timeIntervalSince1970)
                    self.lastUpdate = self.now
                    self.getCurrTime()
                    self.tableView.isUserInteractionEnabled = false
                    self.petetions.removeAll()
                    self.firstSection.removeAll()
                    self.petetions = jsonResult as? CovidData ?? []
                    let inIndex = self.petetions.firstIndex{$0.country == "India"}
                    let totIndex = self.petetions.firstIndex{$0.country == "World"}
                    self.firstSection.append(self.petetions[totIndex!])
                    self.firstSection.append(self.petetions[inIndex!])
                    print(self.firstSection)
                    self.tableView.reloadData()
                    self.stopLoading()
                    self.showToast(message: "Feed updated")
                }
            case .failure(let err):
                print("Failed to fetch courses", err.localizedDescription)
                self.stopLoading()
                DispatchQueue.main.async {
                    let ac = UIAlertController(title: "Oops!", message: "Please check your internet connection", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                    self.present(ac, animated: true, completion: nil)
                }
            }
        }
    }
    
    func getPastDataApi(completion: @escaping (Result<Any, Error>) -> Void) {
        self.loading()
        
        let urlString = "\(API_URL)/covid19/pastData"
        let urlPath = URL(string: urlString)!
        let urlRequest = URLRequest(url: urlPath)
        
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, _, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            
            guard let data = data else { return }
            do {
                let courses = try JSONDecoder().decode(CovidData.self, from: data)
                completion(.success(courses))
            } catch let jsonError {
                completion(.failure(jsonError))
            }        }
        task.resume()
    }
    
    func getCurrTime(){
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MMM-dd HH:mm:ss"
        let date = Date()
        dateString = "Last Update: \(dateFormatter.string(from: date))"
    }
    
    func showToast(message : String) {
        
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.view.backgroundColor = .black
        alert.view.alpha = 0.5
        alert.view.layer.cornerRadius = 15
        self.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.7) {
            alert.dismiss(animated: true)
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return firstSection.count
        }
        return petetions.count - 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = (tableView.dequeueReusableCell(withIdentifier: "PetitionTableViewCell") as! PetitionTableViewCell)
        
        let cellIn = (tableView.dequeueReusableCell(withIdentifier: "IndiaDetailCell") as! IndiaDetailCell)
        
        let petitionIndex = petetions[indexPath.row]
        
        if(indexPath.section == 0) {
            cellIn.country.text = firstSection[indexPath.row].country
            cellIn.death.text = firstSection[indexPath.row].totalDeaths
            cellIn.cases.text = firstSection[indexPath.row].totalCases
            cellIn.recovery.text = firstSection[indexPath.row].totalRecovered
            cellIn.newCases.text = firstSection[indexPath.row].newCases
            cellIn.newDeath.text = firstSection[indexPath.row].newDeaths
            cellIn.newRecovery.text = firstSection[indexPath.row].newRecovered
            return cellIn
        } else {
            cell.country.text = petitionIndex.country
            cell.death.text = petitionIndex.totalDeaths
            cell.cases.text = petitionIndex.totalCases
            cell.recovery.text = petitionIndex.totalRecovered
            cell.newCases.text = petitionIndex.newCases
            cell.newDeath.text = petitionIndex.newDeaths
            cell.newRecovery.text = petitionIndex.newRecovered
            return cell
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = self.storyboard?.instantiateViewController(identifier: "PetitionDetailViewController") as! PetitionDetailViewController
        
        if(indexPath.section == 0) {
            let inIndex = firstSection[indexPath.row]
            vc._country = inIndex.country
            vc._totalCases = inIndex.totalCases
            vc._newCases = inIndex.newCases
            vc._totalDeaths = inIndex.totalDeaths
            vc._newDeaths = inIndex.newDeaths
            vc._totalRecovered = inIndex.totalRecovered
            vc._activeCases = inIndex.activeCases
            vc._seriousCritical = inIndex.seriousCritical
            
        } else{
            let petitionIndex = petetions[indexPath.row]
            vc._country = petitionIndex.country
            vc._totalCases = petitionIndex.totalCases
            vc._newCases = petitionIndex.newCases
            vc._totalDeaths = petitionIndex.totalDeaths
            vc._newDeaths = petitionIndex.newDeaths
            vc._totalRecovered = petitionIndex.totalRecovered
            vc._activeCases = petitionIndex.activeCases
            vc._seriousCritical = petitionIndex.seriousCritical
        }
        
        vc.modalPresentationStyle = .overFullScreen
        self.present(vc, animated: false, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        //Put the Last Update detail on the second section:
        if section == 1 {
            return dateString
        }
        
        return ""
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    
}
