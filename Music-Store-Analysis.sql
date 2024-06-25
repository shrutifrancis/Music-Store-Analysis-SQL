-- Who is the senior most employee based on job title?
Select * From employee
Order By levels desc
Limit 1;

-- Which countries have the most Invoices?
Select billing_country,count(total) as total From invoice
Where total is not Null
Group By billing_country
Order By total Desc 
Limit 5;

-- What are top 3 values of total invoice?
Select total From invoice 
Order By total Desc 
Limit 3;

-- Which city has the best customers? We would like to throw a promotional Music
-- Festival in the city we made the most money. Write a query that returns one city that
-- has the highest sum of invoice totals. Return both the city name & sum of all invoice
-- totals

Select billing_city,sum(total) as invoice_total From invoice
Group By billing_city 
Order By invoice_total Desc;

-- Who is the best customer? The customer who has spent the most money will be
-- declared the best customer. Write a query that returns the person who has spent the
-- most money
Select c.customer_id,first_name,last_name,sum(total) as invoice_total From customer c
Join invoice i on c.customer_id = i.customer_id
Group By c.customer_id
Order By invoice_total Desc
Limit 1;

-- Write query to return the email, first name, last name, & Genre of all Rock Music
-- listeners. Return your list ordered alphabetically by email starting with A

--Method 1---

Select distinct c.email, c.first_name, c.last_name, g.name AS genre
From customer c
Join invoice i On c.customer_id = i.customer_id
Join invoice_line il On i.invoice_id =il.invoice_id
Join track t On il.track_id = t.track_id
Join genre g On t.genre_id = g.genre_id
Where t.track_id In (
    Select t2.track_id
    From track t2
    Join genre g2 On t2.genre_id = g2.genre_id
    Where g2.name Like 'Rock'
)
Order By c.email Asc;

--Method 2---
--This take more time to process because of multiple join
Select distinct c.email, c.first_name, c.last_name, g.name AS genre
From customer c
Join invoice i On c.customer_id = i.customer_id
Join invoice_line il On i.invoice_id =il.invoice_id
Join track t On il.track_id = t.track_id
Join genre g On t.genre_id = g.genre_id
Where g2.name = 'Rock'
Order By c.email Asc;

-- Let's invite the artists who have written the most rock music in our dataset. Write a
-- query that returns the Artist name and total track count of the top 10 rock bands


Select artist.artist_id, artist.name,COUNT(artist.artist_id) AS number_of_songs
From artist
Join album On artist.artist_id = album.artist_id
Join track t On t.album_id = album.album_id
Where t.track_id In (
    Select t2.track_id
    From track t2
    Join genre g2 On t2.genre_id = g2.genre_id
    Where g2.name Like 'Rock'
)
Group By artist.artist_id
Order By number_of_songs DESC
Limit 10;


-- Return all the track names that have a song length longer than the average song length.
-- Return the Name and Milliseconds for each track. Order by the song length with the
-- longest songs listed first

Select name, milliseconds From track
Where Milliseconds > (
	Select avg(Milliseconds) From track
	)
Order By milliseconds Desc;

-- Find how much amount spent by each customer on artists? Write a query to return
-- customer name, artist name and total spent


With cte as
(
	Select artist.artist_id As artist_id, artist.name As artist_name, Sum(invoice_line.unit_price * invoice_line.quantity)
	From invoice_line
	Join track On track.track_id = invoice_line.track_id
	Join album On album.album_id = track.album_id
	Join artist On artist.artist_id = album.artist_id
	Group By artist.artist_id 
	Order By 3 Desc
	Limit 1
)

Select c.customer_id, c.first_name, c.last_name, cte.artist_name, 
SUM(il.unit_price*il.quantity) AS amount_spent
From invoice i
Join customer c On c.customer_id = i.customer_id
Join invoice_line il On il.invoice_id = i.invoice_id
Join track t On t.track_id = il.track_id
Join album alb On alb.album_id = t.album_id
Join cte  On cte.artist_id = alb.artist_id
Group By 1,2,3,4
Order By 5 Desc;


	-- We want to find out the most popular music Genre for each country. We determine the
	-- most popular genre as the genre with the highest amount of purchases. Write a query
	-- that returns each country along with the top Genre. For countries where the maximum
	-- number of purchases is shared return all Genres

-- Method 1: Using CTE ---

With popular_genre As
	(
	    Select Count(invoice_line.quantity) As purchases, customer.country, genre.name, genre.genre_id, 
		Row_Number() Over(Partition By customer.country Order By Count(invoice_line.quantity) Desc) As RowNo 
	    From invoice_line 
		Join invoice On invoice.invoice_id = invoice_line.invoice_id
		Join customer On customer.customer_id = invoice.customer_id
		Join track On track.track_id = invoice_line.track_id
		Join genre On genre.genre_id = track.genre_id
		Group By 2,3,4
		Order By 2 ASC, 1 Desc
	)
Select * From popular_genre Where RowNo <= 1


---Method 2: Using Recursive---

With RECURSIVE
	sales_per_country As
	(
		Select Count(*) As purchases_per_genre, customer.country, genre.name, genre.genre_id
		From invoice_line
		Join invoice On invoice.invoice_id = invoice_line.invoice_id
		Join customer On customer.customer_id = invoice.customer_id
		Join track On track.track_id = invoice_line.track_id
		Join genre On genre.genre_id = track.genre_id
		Group By customer.country, genre.name, genre.genre_id
		Order By customer.country
	),
	max_genre_per_country AS 
	(
		Select Max(purchases_per_genre) As max_genre_number, country
		From sales_per_country
		Group By country
		Order By country 
	)

Select sales_per_country.* 
From sales_per_country
Join max_genre_per_country On sales_per_country.country = max_genre_per_country.country
Where sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;



Write a query that determines the customer that has spent the most on music for each
country. Write a query that returns the country along with the top customer and how
much they spent. For countries where the top amount spent is shared, provide all
customers who spent this amount


-- Method 1: using CTE ----

With Customter_with_country As
	(
		Select customer.customer_id,first_name,last_name,billing_country,Sum(total) As total_spending,
	    Row_Number() Over(Partition By billing_country Order By Sum(total) Desc) As RowNo 
		From invoice
		Join customer On customer.customer_id = invoice.customer_id
		Group By 1,2,3,4
		Order By 4 Asc,5 Desc
	)
	
Select * From Customter_with_country Where RowNo <= 1


--Method 2: Using Recursive---

With RECURSIVE 
	customter_with_country As
	(
		Select customer.customer_id,first_name,last_name,billing_country,Sum(total) As total_spending
		From invoice
		Join customer On customer.customer_id = invoice.customer_id
		Group By 1,2,3,4
		Order By 2,3 Desc
	),

	country_max_spending As
	(
		Select billing_country,Max(total_spending) As max_spending
		From customter_with_country
		Group By billing_country
	)

Select cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
From customter_with_country cc
Join country_max_spending ms
On cc.billing_country = ms.billing_country
Where cc.total_spending = ms.max_spending
Order By 1;

I



























